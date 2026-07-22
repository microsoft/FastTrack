// PR Sweeper — report composer.
//
// Trusted job. Merges the authoritative guardrails result with the advisory
// dual-model AI review, then:
//   * posts / updates ONE sticky comment on the PR,
//   * applies a tidy set of sweeper:* labels (creating any that are missing),
//   * sets a commit status that only fails for hard blocking security findings.
//
// Uses the GitHub REST API directly with the built-in GITHUB_TOKEN.

import { loadConfig, readJsonIfExists } from "./lib.mjs";

const API = "https://api.github.com";
const MARKER = "<!-- pr-sweeper:report -->";
const STATUS_CONTEXT = "PR Sweeper / security";

const TOKEN = process.env.GITHUB_TOKEN;
const REPO = process.env.GITHUB_REPOSITORY; // owner/repo (base)

function headers() {
  return {
    Authorization: `Bearer ${TOKEN}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "Content-Type": "application/json",
  };
}

async function gh(method, path, body) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: headers(),
    body: body ? JSON.stringify(body) : undefined,
  });
  return res;
}

const RISK_BADGE = {
  high: "🔴 **HIGH**",
  medium: "🟠 **MEDIUM**",
  low: "🟢 **LOW**",
};
const SEV_ICON = { block: "⛔", warn: "⚠️", info: "ℹ️" };

const LABEL_DEFS = {
  "sweeper:risk-high": { color: "b60205", description: "PR Sweeper: high risk" },
  "sweeper:risk-medium": { color: "d93f0b", description: "PR Sweeper: medium risk" },
  "sweeper:risk-low": { color: "0e8a16", description: "PR Sweeper: low risk" },
  "sweeper:security-review": { color: "5319e7", description: "PR Sweeper: needs security review" },
  "sweeper:blocked": { color: "8b0000", description: "PR Sweeper: blocking finding" },
  "sweeper:scope-review": { color: "fbca04", description: "PR Sweeper: scope/sensitive-path review" },
  "sweeper:ai-reviewed": { color: "1d76db", description: "PR Sweeper: dual-model AI review attached" },
};

function buildComment(config, guardrails, ai, meta) {
  const risk = guardrails?.risk ?? "low";
  const gateFail = guardrails?.gate === "fail";
  const lines = [];
  lines.push(MARKER);
  lines.push("## 🛰️ PR Sweeper report");
  lines.push("");
  lines.push(
    `**Risk:** ${RISK_BADGE[risk] || risk} · **Security gate:** ${
      gateFail ? "❌ failing (blocking finding)" : "✅ passing"
    } · **Files:** ${guardrails?.summary?.filesChanged ?? "?"}`
  );
  lines.push("");

  // --- Deterministic guardrails (authoritative) ---
  lines.push("### 🔒 Automated guardrails (authoritative)");
  const findings = guardrails?.findings ?? [];
  if (findings.length === 0) {
    lines.push("No secret, PII, file-policy, or scope issues detected. ✅");
  } else {
    lines.push("| | Category | Location | Finding |");
    lines.push("|---|---|---|---|");
    for (const f of findings.slice(0, 40)) {
      const loc = f.file ? `${code(f.file)}${f.line ? `:${f.line}` : ""}` : "—";
      const ev = f.evidence ? ` _(evidence: ${code(f.evidence)})_` : "";
      lines.push(
        `| ${SEV_ICON[f.severity] || ""} | ${safeText(f.category)} | ${loc} | ${safeText(f.message)}${ev} |`
      );
    }
    if (findings.length > 40) lines.push(`| | | | …and ${findings.length - 40} more |`);
  }
  lines.push("");

  // --- Dual-model AI review (advisory) ---
  lines.push("### 🤖 Dual-model AI review (advisory)");
  const reviews = ai?.reviews ?? [];
  const okReviews = reviews.filter((r) => r.status === "ok");
  if (okReviews.length === 0) {
    lines.push(
      "_AI review unavailable for this run (models not reachable or no diff). Guardrails above are unaffected._"
    );
    for (const r of reviews) {
      if (r.status !== "ok") lines.push(`- ${r.label} (\`${r.model}\`): ${r.status}${r.reason ? ` — ${r.reason}` : ""}`);
    }
  } else {
    for (const r of okReviews) {
      const rev = r.review || {};
      lines.push(`<details><summary><strong>${safeText(r.label)}</strong> — <code>${safeText(r.model)}</code> · verdict: <code>${safeText(rev.verdict || "?")}</code> · risk: <code>${safeText(rev.riskLevel || "?")}</code></summary>`);
      lines.push("");
      if (rev.summary) lines.push(safeText(rev.summary));
      if (Array.isArray(rev.security) && rev.security.length) {
        lines.push("");
        lines.push("**Security notes:**");
        for (const s of rev.security.slice(0, 15))
          lines.push(`- ${code(s.severity || "?")} ${s.file ? `${code(s.file)}${s.line ? `:${s.line}` : ""} — ` : ""}${safeText(s.issue || "")}`);
      }
      if (Array.isArray(rev.quality) && rev.quality.length) {
        lines.push("");
        lines.push("**Quality notes:**");
        for (const q of rev.quality.slice(0, 15))
          lines.push(`- ${q.file ? `${code(q.file)} — ` : ""}${safeText(q.note || "")}`);
      }
      lines.push("");
      lines.push("</details>");
      lines.push("");
    }
  }
  lines.push("");

  // --- Next steps for the contributor ---
  const steps = collectNextSteps(guardrails, okReviews);
  if (steps.length) {
    lines.push("### ✅ Suggested next steps");
    for (const s of steps.slice(0, 12)) lines.push(`- [ ] ${safeText(s)}`);
    lines.push("");
  }

  lines.push("---");
  lines.push(
    "_The automated guardrails are authoritative and gate the security status. The AI review is advisory and never auto-merges. Thanks for contributing to FastTrack!_ 🛩️"
  );
  return lines.join("\n");
}

function collectNextSteps(guardrails, okReviews) {
  const steps = [];
  for (const f of guardrails?.findings ?? []) {
    if (f.severity === "block") {
      if (f.category === "secret")
        steps.push(`Remove the secret at \`${f.file}\`${f.line ? `:${f.line}` : ""}, rotate it, and scrub it from git history.`);
      else if (f.id === "blocked-extension")
        steps.push(`Remove the disallowed binary/executable \`${f.file}\`.`);
    }
  }
  for (const f of guardrails?.findings ?? []) {
    if (f.severity === "warn" && f.category === "pii")
      steps.push(`Confirm \`${f.file}\`${f.line ? `:${f.line}` : ""} contains no customer/personal data.`);
  }
  for (const r of okReviews) {
    for (const s of r.review?.suggestedNextSteps ?? []) steps.push(s);
  }
  return [...new Set(steps)];
}

function desiredLabels(guardrails, ai) {
  const set = new Set();
  const risk = guardrails?.risk ?? "low";
  set.add(`sweeper:risk-${risk}`);
  if (guardrails?.gate === "fail") set.add("sweeper:blocked");
  if ((guardrails?.summary?.securityFindingCount ?? 0) > 0 || guardrails?.gate === "fail")
    set.add("sweeper:security-review");
  if (
    (guardrails?.summary?.sensitivePaths?.length ?? 0) > 0 ||
    (guardrails?.summary?.outOfScope?.length ?? 0) > 0
  )
    set.add("sweeper:scope-review");
  if ((ai?.reviews ?? []).some((r) => r.status === "ok")) set.add("sweeper:ai-reviewed");
  return set;
}

// Neutralise untrusted prose (AI-model output or PR-derived text) before it is
// embedded in the trusted bot's sticky comment. Prevents a prompt-injected model
// (or crafted PR content) from posting real HTML, links, images, or @mentions.
function safeText(s) {
  return String(s ?? "")
    .replace(/\r?\n/g, " ")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/!\[/g, "!\u200b[") // defuse image  ![alt](url)
    .replace(/\]\(/g, "]\u200b(") // defuse link   [text](url)
    .replace(/@/g, "@\u200b") // defuse @mentions
    .replace(/\|/g, "\\|")
    .trim();
}

// Render an untrusted value inside an inline-code span, stripping backticks so it
// cannot break out of the span.
function code(s) {
  return `\`${String(s ?? "").replace(/`/g, "'").replace(/\r?\n/g, " ").trim()}\``;
}

async function upsertComment(number, body) {
  let page = 1;
  let existing = null;
  while (true) {
    const res = await gh("GET", `/repos/${REPO}/issues/${number}/comments?per_page=100&page=${page}`);
    if (!res.ok) break;
    const batch = await res.json();
    const hit = batch.find((c) => typeof c.body === "string" && c.body.includes(MARKER));
    if (hit) {
      existing = hit;
      break;
    }
    if (batch.length < 100) break;
    page++;
  }
  if (existing) {
    const res = await gh("PATCH", `/repos/${REPO}/issues/comments/${existing.id}`, { body });
    console.log(`Comment ${res.ok ? "updated" : `update failed (${res.status})`}.`);
  } else {
    const res = await gh("POST", `/repos/${REPO}/issues/${number}/comments`, { body });
    console.log(`Comment ${res.ok ? "created" : `create failed (${res.status})`}.`);
  }
}

async function ensureLabels(names) {
  for (const name of names) {
    const def = LABEL_DEFS[name];
    if (!def) continue;
    const res = await gh("GET", `/repos/${REPO}/labels/${encodeURIComponent(name)}`);
    if (res.status === 404) {
      await gh("POST", `/repos/${REPO}/labels`, {
        name,
        color: def.color,
        description: def.description,
      });
    }
  }
}

async function applyLabels(number, desired) {
  // Fetch current labels; remove stale sweeper:* labels, add desired ones.
  const res = await gh("GET", `/repos/${REPO}/issues/${number}/labels`);
  const current = res.ok ? (await res.json()).map((l) => l.name) : [];
  const staleSweeper = current.filter((n) => n.startsWith("sweeper:") && !desired.has(n));
  for (const name of staleSweeper) {
    await gh("DELETE", `/repos/${REPO}/issues/${number}/labels/${encodeURIComponent(name)}`);
  }
  const toAdd = [...desired].filter((n) => !current.includes(n));
  if (toAdd.length) {
    await gh("POST", `/repos/${REPO}/issues/${number}/labels`, { labels: toAdd });
  }
  console.log(`Labels applied: ${[...desired].join(", ") || "(none)"}`);
}

async function setStatus(sha, guardrails) {
  if (!sha) return;
  const fail = guardrails?.gate === "fail";
  const state = fail ? "failure" : "success";
  const blockCount = guardrails?.summary?.blockCount ?? 0;
  const description = fail
    ? `${blockCount} blocking security finding(s) — see PR Sweeper comment`
    : `No blocking findings (risk: ${guardrails?.risk ?? "low"})`;
  const res = await gh("POST", `/repos/${REPO}/statuses/${sha}`, {
    state,
    context: STATUS_CONTEXT,
    description: description.slice(0, 140),
  });
  console.log(`Commit status ${res.ok ? `set (${state})` : `failed (${res.status})`}.`);
}

async function resolvePrNumberFromSha(sha) {
  // Bind the PR number to the TRUSTED head SHA from the workflow_run event.
  // Works for fork PRs (where workflow_run.pull_requests is empty) because the
  // head commit is reachable via refs/pull/N/head in the base repo.
  const res = await gh("GET", `/repos/${REPO}/commits/${encodeURIComponent(sha)}/pulls?per_page=100`);
  if (!res.ok) return null;
  const pulls = await res.json();
  if (!Array.isArray(pulls) || pulls.length === 0) return null;
  const match =
    pulls.find((p) => p.state === "open" && p.base?.repo?.full_name === REPO) || pulls[0];
  return match?.number ?? null;
}

async function main() {
  if (!TOKEN || !REPO) {
    console.error("Missing GITHUB_TOKEN or GITHUB_REPOSITORY.");
    process.exit(1);
  }
  const config = await loadConfig();
  const guardrails = readJsonIfExists("guardrails.json", null);
  const ai = readJsonIfExists("ai-review.json", { reviews: [] });
  const meta = readJsonIfExists("pr-meta.json", {});

  if (!guardrails) {
    console.error("No guardrails result — nothing to report.");
    process.exit(1);
  }

  // --- Establish TRUSTED write targets ---------------------------------------
  // The artifact's self-reported number/headSha are attacker-controlled, so we
  // never use them to target writes. Identity comes from the workflow_run event.
  const trustedSha = process.env.TRUSTED_HEAD_SHA || null;
  if (meta?.headSha && trustedSha && meta.headSha !== trustedSha) {
    console.warn(
      `Artifact headSha (${meta.headSha}) does not match trusted head SHA (${trustedSha}); using trusted value.`
    );
  }
  const headSha = trustedSha || null;

  let number = null;
  const envNum = parseInt(process.env.TRUSTED_PR_NUMBER || "", 10);
  if (Number.isInteger(envNum) && envNum > 0) number = envNum;
  if (!number && headSha) number = await resolvePrNumberFromSha(headSha);

  if (!number) {
    console.error("Could not resolve a trusted PR number from the workflow_run event; aborting.");
    process.exit(1);
  }

  const body = buildComment(config, guardrails, ai, meta);
  const desired = desiredLabels(guardrails, ai);

  await upsertComment(number, body);
  if (config.labels?.ensureExist) await ensureLabels(desired);
  await applyLabels(number, desired);
  await setStatus(headSha, guardrails);

  console.log(`PR Sweeper report complete for PR #${number} (${headSha || "no sha"}).`);
}

main().catch((err) => {
  console.error("report.mjs failed:", err);
  process.exit(1);
});
