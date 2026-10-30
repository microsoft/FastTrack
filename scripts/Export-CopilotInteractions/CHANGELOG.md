# Changelog

## 2.0.0 - 2026-10-29

- Limited exports to users with an eligible Microsoft 365 Copilot license. Copilot Chat (Basic) usage from users without that license is not collected by this exporter.
- Added service-plan-based eligibility detection, including qualifying bundles. Disabled plans and unavailable user capabilities do not qualify.
- Replaced delegated-only `licenseDetails` calls with app-only-compatible user assignments and tenant `subscribedSkus`.
- Added `-CopilotServicePlans`. The `-SkuTierMap` fallback accepts only `Premium` mappings and cannot override disabled or unavailable user plans.
- Added `UsersSkippedWithoutCopilotLicense`. Missing required license metadata is reported as an error, not counted as an unlicensed user.
- Documented that license classification reflects current assignments, not historical license status.
- Added synthetic, offline regression tests.

### Breaking changes

- Removed `basicUsers` from `UsageByAppFeatureDay.csv`. Update downstream queries that reference it.
- Removed `-Interactive`: the interaction-export API does not support delegated authentication. Use a client secret or certificate.
- Replaced the unused `Reports.Read.All` requirement with `LicenseAssignment.Read.All`. Existing app registrations need admin consent for the new application permission.
- Removed `Basic` and `Unknown` license tiers. Exported users retain `copilotTier = Premium` as a compatibility label.

## 1.0.0 - 2026-05-21

- Initial release.
