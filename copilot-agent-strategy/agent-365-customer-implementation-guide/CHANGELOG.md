# Changelog

All notable changes to the Microsoft Agent 365 Customer Implementation Guide are documented here.

## 1.2.0 - 2026-09-25

- Removed the "Value plays" section, its navigation link, the related hero metric, CSS, and scripts. Its Microsoft Defender advanced hunting queries now live where you use them: the Simple checklist row **Hunt for agent inventory and activity with advanced hunting** and Detailed task **2a**, each with a schema check, eight sample queries, and copy buttons. The queries were rechecked against current Microsoft Learn schemas; the activity query now filters on the documented Agent 365 `ActionType` values, and the behavior query summarizes the values your tenant emits.
- Added a subtle community note at the top and in the footer of both views: the guide is community-built and community-supported, isn't official Microsoft documentation, is a template to review and tailor, and is open to contributions.
- Tailored the content for public readers: removed seller and delivery wording (the "POV narrative arc" diagram, "[Demo]" labels, "customer tenant" phrasing, the account-team pill, "Public" source pills, a Message Center entry with no link, and meta notes about exports and preview windows) and rewrote consultant-perspective phrasing in the Detailed view to address your organization directly.
- Simplified the Simple view: sections now follow the navigation order (Understand, Prepare, Configure, Go deeper, Reference); removed the redundant "Security and compliance stack" section (its identity-enforcement note moved to Caveats), the Agent Dashboard tour, and the adjacent Copilot prompt-DLP demo; collapsed the stage-by-stage lifecycle walkthroughs by default (they still print); grouped References by topic and dropped stale Microsoft 365 Roadmap status entries.
- Accuracy updates from a review against Microsoft Learn: the Microsoft 365 admin center **Delete** action (30-day soft delete, restore, and permanent delete) replaces the claim that only Agent Builder supports admin-center delete; Agent Builder agents send observability data by default; Agent Builder groups can be chat users but not owners; Foundry hosted agents and other platforms need instrumentation, with the Microsoft OpenTelemetry Distro now recommended; registry sync (preview) is now documented as **Connected platforms**, with seven supported platforms and the current admin center path; Identity Protection for agents and Conditional Access licensing notes match current wording.
- Made the Detailed view more concise (about 20% less text than 1.1.1, even with the added queries) without dropping steps: Entra (tab 3) is 55% shorter because each task no longer repeats its procedure, validation, rollback, and references twice, and it now uses current Entra admin center paths; custom pro-code agents (tab 12) is 45% shorter and shadow and local agents (tab 13) is 35% shorter, with repeated caveats and meta commentary merged. All commands, code, KQL, portal paths, roles, and known limitations were kept. Task 3d now notes that access packages for agent identities can include only security groups, Microsoft Entra roles, or API permissions, and that the documented agent flow relies on expiration and sponsor-approved extensions rather than access reviews (the Simple view wording matches). The overview now combines its two onboarding tables into one and drops a protections table that repeated 15f. Also removed references to screenshots the guide doesn't contain, screenshot redaction tables, and leftover authoring notes.
- Fixed the Detailed rail item for tab 15, which scrolled into the Entra tab and didn't show its progress count, and made the Shadow AI portal path consistent (**Agents → Shadow AI**).
- Fixed links that returned "page not found": seven Microsoft Learn links in the Detailed view now point to current pages (policy templates, agent settings, Agent Builder org catalog submission, Copilot DLP, DSPM permissions, eDiscovery for AI data, and the Agent 365 SDK capabilities overview), and every link in both views was rechecked.
- Polished the UI: disabled code-font ligatures so KQL operators such as `!=` display as typed, made in-page links open collapsed sections, removed empty navigation groups and a duplicated heading from the Detailed view, corrected the Detailed view's static task counts, defined "MAC", and standardized US English spelling and date formats.
- Refreshed `preview.webp` so the catalog card shows the current guide.

## 1.1.1 - 2026-09-14

- Fixed the Detailed navigation so selecting an item in the left rail scrolls the matching section into view while keeping all task content visible. Arrow key, Home, and End navigation use the same behavior and respect the reader's reduced-motion preference.
- Added a discoverable **Submit feedback** link to the guide header in both Simple and Detailed modes. The native link opens the FastTrack issues list and remains available when scripts are restricted.

## 1.1.0 - 2026-09-11

- Removed the "Roadmap" section and its navigation link from the Simple view, along with the section's dedicated CSS. Legitimate references to the public Microsoft 365 Roadmap elsewhere in the guide are unchanged.
- Added the public Agent 365 whole-system architecture diagram as the first card in the Diagrams section, extracted faithfully from the public Agent 365 Lifecycle Atlas. The diagram is embedded inline (keeping the guide self-contained and offline), follows the guide's light/dark theme, offers an accessible native modal enlargement, carries a source attribution, and links onward with "For more diagrams, click here" to https://aka.ms/fasttrackext/a365diagram.

## 1.0.4 - 2026-09-10

- Removed the visible wrapper credit footer (author credits and the "View full MIT License" disclosure) so the guide fills the full viewport height. The author attribution and complete MIT License notice are retained in a non-rendered HTML source comment, so downloaded copies keep the attribution and license. Guide content, Simple/Detailed switching, theme, and print controls are unchanged.

## 1.0.3 - 2026-09-09

- Made the wrapper credit footer visually quieter with restrained spacing, slightly smaller but readable type, and a muted disclosure control. Author credits, the full MIT License text, keyboard access, and theme behavior are unchanged.

## 1.0.2 - 2026-09-09

- Added a `preview.webp` catalog screenshot and `preview` metadata so the catalog detail page shows a real preview of the guide. Guide content is unchanged.

## 1.0.1 - 2026-09-09

- Added `interactiveKind: guide` catalog metadata so the catalog labels this resource an "Interactive guide". Guide content is unchanged.

## 1.0.0 - 2026-09-09

- Published the self-contained customer implementation guide.
- Included Simple and Detailed experiences with all runtime dependencies and images inline.
- Added public authorship and MIT license information.
