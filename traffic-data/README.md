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
