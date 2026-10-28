# Traffic Data

This directory is automatically populated by the [traffic-stats workflow](../.github/workflows/traffic-stats.yml).
Daily collection is committed to the durable `automation/traffic-stats-staging`
branch so Clarity's three-day export window is preserved without daily pull requests.

**Files:**
- `YYYY-MM-DD.json` — Full daily snapshot (views, clones, referrers, popular paths)

Data is collected daily at 06:00 UTC via GitHub Actions. Each Friday at 08:00
`America/Chicago` (including daylight saving time), the workflow updates one
review-required pull request from the Friday-only `automation/traffic-stats-weekly`
branch to `master`. Daily pushes to the staging branch therefore do not change the
open weekly review. If the optional `AUTOMATION_PAT` is not configured or cannot
create pull requests, the workflow prints a manual compare URL; daily collection
continues safely on the staging branch.

## Manual collection

When the scheduled workflow cannot authenticate (for example, its `TRAFFIC_TOKEN` expired), collect a snapshot by hand. GitHub keeps only a rolling 14 days of traffic, so run this at least every two weeks to avoid gaps. Each snapshot overlaps the previous one, and analysis unions days by date, so extra runs never double count.

1. Sign in with an account that has **push access** to `microsoft/FastTrack` and whose token is authorized for the Microsoft organization's SAML SSO:

   ```powershell
   gh auth login
   gh api repos/microsoft/FastTrack/traffic/views --jq .count   # should print a number, not an SSO error
   ```

2. Collect the snapshot and commit it:

   ```powershell
   npm ci --prefix tools/catalog-build
   npm run collect:traffic --prefix tools/catalog-build
   git add traffic-data
   git commit -m "Traffic data for $(Get-Date -Format yyyy-MM-dd)"
   ```

   The command writes `traffic-data/YYYY-MM-DD.json` in the same format as the workflow.

3. Optional: refresh the per-resource view counts shown on the site. This needs a Clarity project API token (Clarity does not keep more than three days of history, so the scheduled workflow is the only way to avoid gaps):

   ```powershell
   $env:CLARITY_API_TOKEN = "<token>"
   npm run build:stats --prefix tools/catalog-build
   ```

## Known gaps

The scheduled workflow stopped authenticating on 2026-07-22, and the last snapshot before the fix is `2026-06-30.json`. GitHub does not keep older traffic, so views and clones from 2026-07-01 through 2026-10-13 could not be recovered. Collection resumed with a manual snapshot, `2026-10-28.json`, which covers 2026-10-14 through 2026-10-27.
