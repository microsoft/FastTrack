// PR Sweeper — deterministic guardrails engine (authoritative).
//
// Runs in the TRUSTED report job over the DATA artifact captured from the PR.
// It makes no network calls and cannot be prompt-injected, so its verdict is the
// one that actually gates a merge. Output: sweeper-artifact/guardrails.json.

import {
  loadConfig,
  readTextIfExists,
  readJsonIfExists,
  writeJson,
  parseDiff,
  parseNameStatus,
  parseSizes,
  matchesAnyGlob,
  redact,
  extname,
  topRoot,
} from "./lib.mjs";

const SEVERITY_RANK = { block: 3, warn: 2, info: 1 };

async function main() {
  const config = await loadConfig();
  const patch = readTextIfExists("diff.patch");
  const nameStatus = parseNameStatus(readTextIfExists("name-status.tsv"));
  const sizes = parseSizes(readTextIfExists("sizes.tsv"));
  const meta = readJsonIfExists("pr-meta.json", {});

  const files = parseDiff(patch);
  const findings = [];
  const add = (f) => findings.push(f);

  const secretRegexes = config.secretPatterns.map((p) => {
    // Node's RegExp does not accept an inline (?i) marker in the body, so we
    // strip it and hoist to the case-insensitive flag instead.
    const ci = p.regex.includes("(?i)");
    const body = ci ? p.regex.replace(/\(\?i\)/g, "") : p.regex;
    return { ...p, re: new RegExp(body, ci ? "gi" : "g") };
  });

  const emailRe = new RegExp(config.pii.emailRegex, "gi");
  const ipRe = new RegExp(config.pii.ipRegex, "g");

  // ---- Content scans over ADDED lines --------------------------------------
  for (const file of files) {
    for (const { line, text } of file.added) {
      // Secrets
      for (const p of secretRegexes) {
        p.re.lastIndex = 0;
        const m = p.re.exec(text);
        if (m) {
          add({
            category: "secret",
            severity: p.severity,
            file: file.path,
            line,
            id: p.id,
            message: `Possible ${p.label} detected in added content.`,
            evidence: redact(m[0]),
          });
        }
      }
      // PII: emails (excluding safe domains)
      emailRe.lastIndex = 0;
      let em;
      while ((em = emailRe.exec(text)) !== null) {
        const domain = em[0].split("@")[1]?.toLowerCase() || "";
        const safe = config.pii.allowedEmailDomains.some(
          (d) => domain === d || domain.endsWith(`.${d}`)
        );
        if (!safe) {
          add({
            category: "pii",
            severity: "warn",
            file: file.path,
            line,
            id: "email",
            message: "Possible personal/customer email address — confirm it is not customer data.",
            evidence: redact(em[0]),
          });
          break; // one per line is enough signal
        }
      }
      // PII: public IP addresses
      ipRe.lastIndex = 0;
      let ip;
      while ((ip = ipRe.exec(text)) !== null) {
        const value = ip[0];
        const octets = value.split(".").map(Number);
        const validIp = octets.length === 4 && octets.every((o) => o >= 0 && o <= 255);
        const ignored = config.pii.ignoreIpPrefixes.some((pre) => value.startsWith(pre));
        if (validIp && !ignored) {
          add({
            category: "pii",
            severity: "warn",
            file: file.path,
            line,
            id: "public-ip",
            message: "Public IP address in added content — confirm it is not customer infrastructure.",
            evidence: value,
          });
          break;
        }
      }
    }
  }

  // ---- File-policy + scope scans -------------------------------------------
  // Drive these off the authoritative name-status list (every changed path,
  // including binaries that produce no unified-diff hunk), enriched with the
  // parsed-diff entry when one exists.
  const byPath = new Map(files.map((f) => [f.path, f]));
  const changedPaths = [
    ...new Set([...Object.keys(nameStatus), ...files.map((f) => f.path)]),
  ];
  const rootsTouched = new Set();
  const sensitiveTouched = [];
  const outOfScope = [];
  let totalAdded = 0;

  for (const path of changedPaths) {
    const file = byPath.get(path);
    totalAdded += file?.addedCount || 0;
    const status = nameStatus[path] || "M";
    const isAdded = status === "A";
    const ext = extname(path);
    const bytes = sizes[path];
    const isBinary = file?.binary || false;

    // Blocked extensions — only for files present in the PR head (added/modified).
    // Deleting a forbidden artifact is a good thing and must not fail the gate.
    if (config.files.blockedExtensions.includes(ext) && status !== "D") {
      add({
        category: "file-policy",
        severity: "block",
        file: path,
        id: "blocked-extension",
        message: `Disallowed file type "${ext}". Binaries/executables/archives are not accepted.`,
      });
    } else if (isBinary && isAdded && !config.files.allowedBinaryExtensions.includes(ext)) {
      add({
        category: "file-policy",
        severity: "warn",
        file: path,
        id: "unexpected-binary",
        message: `New binary file with unrecognised type "${ext || "(none)"}" — verify it belongs in the catalog.`,
      });
    }

    // Oversized files
    if (typeof bytes === "number" && bytes > config.files.maxFileSizeBytes) {
      add({
        category: "file-policy",
        severity: "warn",
        file: path,
        id: "oversized-file",
        message: `File is ${(bytes / (1024 * 1024)).toFixed(1)} MB, above the ${(
          config.files.maxFileSizeBytes /
          (1024 * 1024)
        ).toFixed(0)} MB review threshold.`,
      });
    }

    // Scope classification
    const root = topRoot(path);
    const inContentRoot = config.contentRoots.includes(root);
    const alwaysAllowed = config.alwaysAllowedPaths.includes(path);
    const isSensitive = matchesAnyGlob(path, config.sensitivePaths);

    if (isSensitive) sensitiveTouched.push(path);
    if (inContentRoot) rootsTouched.add(root);
    if (!inContentRoot && !alwaysAllowed && !isSensitive) outOfScope.push(path);

    // catalog.json must never be hand-edited (it is generated).
    if (path === "catalog.json") {
      add({
        category: "scope",
        severity: "warn",
        file: path,
        id: "catalog-hand-edit",
        message: "catalog.json is generated by tools/catalog-build and must not be edited by hand.",
      });
    }
  }

  if (sensitiveTouched.length > 0) {
    add({
      category: "scope",
      severity: "warn",
      id: "sensitive-path",
      message: `Touches security-sensitive path(s): ${sensitiveTouched.join(", ")}. Maintainer + security review required.`,
    });
  }
  if (outOfScope.length > 0) {
    add({
      category: "scope",
      severity: "info",
      id: "out-of-scope",
      message: `Change(s) outside known content roots: ${outOfScope.slice(0, 10).join(", ")}${
        outOfScope.length > 10 ? " …" : ""
      }.`,
    });
  }
  if (rootsTouched.size > config.scope.maxContentRoots) {
    add({
      category: "scope",
      severity: "info",
      id: "multi-root",
      message: `Spans ${rootsTouched.size} content roots (${[...rootsTouched].join(
        ", "
      )}). CONTRIBUTING asks for one focused change — consider splitting.`,
    });
  }
  if (changedPaths.length > config.files.largeChangeFileCount) {
    add({
      category: "scope",
      severity: "info",
      id: "large-change",
      message: `Large PR: ${changedPaths.length} files changed. Smaller PRs are easier to review.`,
    });
  }

  // ---- Risk roll-up ---------------------------------------------------------
  const hasBlock = findings.some((f) => f.severity === "block");
  const hasWarn = findings.some((f) => f.severity === "warn");
  const risk = hasBlock ? "high" : hasWarn ? "medium" : "low";
  const securityFindings = findings.filter(
    (f) => (f.category === "secret" || f.category === "pii") && f.severity !== "info"
  );

  findings.sort((a, b) => (SEVERITY_RANK[b.severity] || 0) - (SEVERITY_RANK[a.severity] || 0));

  const result = {
    schema: 1,
    pr: meta.number ?? null,
    risk,
    gate: hasBlock ? "fail" : "pass", // hard gate: only true blocks fail the status
    summary: {
      filesChanged: changedPaths.length,
      linesAdded: totalAdded,
      contentRoots: [...rootsTouched],
      sensitivePaths: sensitiveTouched,
      outOfScope,
      blockCount: findings.filter((f) => f.severity === "block").length,
      warnCount: findings.filter((f) => f.severity === "warn").length,
      infoCount: findings.filter((f) => f.severity === "info").length,
      securityFindingCount: securityFindings.length,
    },
    findings,
  };

  writeJson("guardrails.json", result);
  console.log(
    `Guardrails: risk=${risk} gate=${result.gate} block=${result.summary.blockCount} warn=${result.summary.warnCount} info=${result.summary.infoCount}`
  );
}

main().catch((err) => {
  console.error("guardrails.mjs failed:", err);
  process.exit(1);
});
