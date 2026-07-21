# Archived Scripts

This folder holds FastTrack scripts that are **no longer actively maintained**. They were moved here during a content review because they had not been updated in **3+ years** and, in many cases, target technologies that have since been deprecated or significantly changed (e.g. Yammer classic, SharePoint Migration Tool logs, legacy Teams/OneDrive licensing flows).

## Why archive instead of delete?

- **History is preserved** — every script and its full git history moves intact (`git mv`), so nothing is lost.
- **Existing links keep working** at the new `scripts/archive/<name>` path.
- **The catalog build ignores `archive/`**, so these no longer surface as recommended, active tooling on the site while remaining available for reference.

## Support expectations

These scripts are provided **as-is with no ongoing maintenance**. They may reference deprecated modules, endpoints, or admin experiences. Validate against current documentation before use. If you rely on one of these and want it brought back to active status, open a PR that refreshes it and adds the required catalog front matter — we'll gladly un-archive maintained tools.

## What's here

Archived on 2026-07-21 — last-updated age at time of archival:

| Script | Last updated |
| --- | --- |
| Get-FullOwnerReport | 2018-05 (~8y) |
| Get-OD4BExternalUsers | 2018-05 (~8y) |
| Get-FullTeamsReport | 2018-06 (~8y) |
| move-team | 2018-08 (~8y) |
| Get-ODBUsage | 2018-08 (~8y) |
| Disable-TeamsAudioVideo | 2018-08 (~8y) |
| split-spmtlogerrors | 2018-10 (~8y) |
| Get-DocLibInventory | 2018-12 (~8y) |
| Set-ForwardingSMTPAddress | 2019-01 (~8y) |
| AddRemove-OneDriveSecondaryAdmin | 2019-04 (~7y) |
| Get-GroupsTeamsSites | 2019-05 (~7y) |
| Get-ListUsage | 2019-06 (~7y) |
| Update-TeamsLicense | 2019-08 (~7y) |
| Disable-TeamifyPrompt | 2020-01 (~6y) |
| Merge-SPMTResults | 2020-02 (~6y) |
| Get-YammerPrivateContentModeAdmins | 2020-09 (~6y) |
| Get-TeamVisibilityAndOwnerReport | 2021-03 (~5y) |
| Get-MigrationToTeamsDNSCheck | 2021-04 (~5y) |
| Find-MailboxDelegates batch analysis | 2021-05 (~5y) |
| get-teamsusage | 2021-06 (~5y) |
| Get-LicensingInfo | 2022-01 (~4y) |
| Get-MgUserVoicemailReport | 2022-03 (~4y) |
| Update-BookingsAdminPermissions | 2022-04 (~4y) |
| Get-AgentCQFinder | 2022-05 (~4y) |
| Get-TeamsChannelUsersReport | 2022-09 (~4y) |
| Get-AuditGuestTeams | 2022-09 (~4y) |
| Get-SharedChannelsUserIsPartOf | 2022-11 (~4y) |
