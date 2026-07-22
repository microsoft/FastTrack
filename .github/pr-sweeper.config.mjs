// Intelligent PR Sweeper — configuration
// ---------------------------------------
// This file is ALWAYS loaded from the trusted base repository (never from a
// pull-request head), so a contributor cannot weaken the guardrails by editing
// their own copy. Tune the values here; no workflow YAML edits required.
//
// Everything is plain JavaScript, so you can add comments and computed values.

export default {
  // Where catalog resources are allowed to live. Changes entirely outside these
  // roots (plus the always-allowed housekeeping paths below) get flagged as
  // "out of scope" so reviewers notice unexpected edits.
  contentRoots: [
    "scripts",
    "samples",
    "tools",
    "docs",
    "copilot-agent-samples",
    "copilot-agent-strategy",
    "copilot-analytics-samples",
    "copilot-prompt-samples",
    "traffic-data",
  ],

  // Paths a normal contribution may touch even though they are not content roots.
  alwaysAllowedPaths: [
    "README.md",
    "CHANGELOG.md",
    "TEMPLATE-README.md",
    ".gitignore",
  ],

  // Editing anything matching these globs is not blocked, but it is surfaced
  // prominently and always routed to a maintainer / security review. These are
  // the "blast radius" files: CI, supply chain, licensing, generated catalog.
  sensitivePaths: [
    ".github/workflows/**",
    ".github/scripts/**",
    ".github/pr-sweeper.config.mjs",
    ".github/CODEOWNERS",
    ".github/dependabot.yml",
    "catalog.json",           // generated — must never be hand-edited
    "LICENSE",
    "LICENSE-CODE",
    "SECURITY.MD",
  ],

  files: {
    // Added files with these extensions are blocked. Binaries and archives are a
    // common vector for slipping unreviewable / malicious content into a repo.
    blockedExtensions: [
      ".exe", ".dll", ".so", ".dylib", ".bin", ".msi", ".bat", ".cmd", ".com",
      ".scr", ".jar", ".zip", ".7z", ".rar", ".gz", ".tar", ".tgz", ".iso",
      ".pfx", ".p12", ".keystore", ".jks",
    ],
    // Binary formats we legitimately publish (Power BI, PowerPoint, images).
    // These are allowed but still size-checked.
    allowedBinaryExtensions: [".pbix", ".pptx", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".pdf"],
    // Any added/binary file larger than this is flagged for manual review.
    maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
    // A single PR touching more than this many files is flagged as "large"
    // (contributor-friendliness: we ask them to split, we do not block).
    largeChangeFileCount: 60,
  },

  scope: {
    // How many distinct content roots a single PR may touch before we nudge the
    // contributor to split it (CONTRIBUTING asks for one focused change).
    maxContentRoots: 3,
  },

  review: {
    // Dual-model review. Each slot is an independent reviewer; their findings are
    // shown side by side plus a merged consensus. AI output is ADVISORY ONLY and
    // never gates a merge — the deterministic guardrails are authoritative.
    //
    // provider "github-models" needs only `permissions: models: read` (built-in
    // GITHUB_TOKEN). To use a model GitHub Models does not host (e.g. Anthropic
    // Claude Opus 4.8), set provider "azure-openai" and supply the endpoint here
    // plus the api key via the AZURE_OPENAI_API_KEY repo secret.
    providers: [
      {
        slot: "fast",
        label: "GPT-class reviewer",
        provider: "github-models",
        model: "openai/gpt-5",
        temperature: 0.1,
      },
      {
        slot: "deep",
        label: "Deep-reasoning reviewer",
        provider: "github-models",
        model: "openai/o3",
        // o-series reasoning models reject a non-default temperature, so we omit
        // it (null = "don't send the field"). Set a number for non-reasoning models.
        temperature: null,
        // To wire the *real* Claude Opus 4.8 here instead, deploy it on
        // Azure AI Foundry (Anthropic models are available there) and use:
        //   provider: "azure-openai",
        //   endpoint: "https://<resource>.services.ai.azure.com/models",
        //   model: "<your-opus-4.8-deployment>",
        // then add the AZURE_OPENAI_API_KEY secret. Leave as-is to run on the
        // built-in, zero-secret GitHub Models path.
      },
    ],
    maxDiffChars: 60000, // truncate very large diffs sent to the models
    timeoutMs: 60000,
  },

  // Deterministic secret detectors. Matched only against ADDED lines in the diff.
  // Keep evidence redacted in output — never echo a full secret back into a PR.
  secretPatterns: [
    { id: "private-key", label: "Private key block", regex: "-----BEGIN (?:RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----", severity: "block" },
    { id: "aws-access-key", label: "AWS access key id", regex: "\\bAKIA[0-9A-Z]{16}\\b", severity: "block" },
    { id: "github-pat", label: "GitHub token", regex: "\\bgh[pousr]_[A-Za-z0-9]{36,}\\b", severity: "block" },
    { id: "github-fine-pat", label: "GitHub fine-grained token", regex: "\\bgithub_pat_[A-Za-z0-9_]{60,}\\b", severity: "block" },
    { id: "slack-token", label: "Slack token", regex: "\\bxox[baprs]-[A-Za-z0-9-]{10,}\\b", severity: "block" },
    { id: "google-api-key", label: "Google API key", regex: "\\bAIza[0-9A-Za-z_\\-]{35}\\b", severity: "block" },
    { id: "azure-storage-conn", label: "Azure storage connection string", regex: "AccountKey=[A-Za-z0-9+/=]{40,}", severity: "block" },
    { id: "azure-sas", label: "Azure SAS signature", regex: "[?&]sig=[A-Za-z0-9%]{20,}", severity: "warn" },
    { id: "generic-secret-assign", label: "Hardcoded secret assignment", regex: "(?i)(password|passwd|pwd|secret|client_secret|api[_-]?key|apikey|access[_-]?token|auth[_-]?token|connection[_-]?string)\\s*[:=]\\s*['\"][^'\"\\s]{8,}['\"]", severity: "warn" },
    { id: "jwt", label: "JSON Web Token", regex: "\\beyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\b", severity: "warn" },
    { id: "pem-cert", label: "Certificate block", regex: "-----BEGIN CERTIFICATE-----", severity: "warn" },
  ],

  // Possible customer / personal data. Conservative — these are "warn" and are
  // meant to prompt a human check, not to block. Common docs/sample values are
  // excluded to keep the noise down.
  pii: {
    emailRegex: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
    // Emails ending in these are treated as safe (examples, MS system addresses).
    allowedEmailDomains: [
      "example.com", "example.org", "contoso.com", "microsoft.com",
      "users.noreply.github.com", "noreply.github.com",
    ],
    // Public/reserved/documentation IP ranges we ignore.
    ignoreIpPrefixes: ["10.", "192.168.", "127.", "0.", "255.", "172.16.", "203.0.113.", "198.51.100.", "192.0.2."],
    ipRegex: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b",
  },

  labels: {
    prefix: "sweeper",
    ensureExist: true, // create any missing labels via the API
  },
};
