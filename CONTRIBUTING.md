# Contribute to Microsoft FastTrack

Thank you for contributing to the Microsoft FastTrack public catalog. Keep each pull request focused on one resource, bug fix, or documentation change. If you have questions, open an issue before investing in a large contribution.

## Before you start

- Create a topic branch; pull requests from `master` are not accepted.
- Sync your branch with the current `master` before opening the pull request.
- Do not include personal data, customer-specific information, credentials, or other private details.
- Do not include software, dependencies, or copied code that conflicts with the repository licenses.
- Put scripts in a slug-cased folder under `scripts/`. Follow the existing content-root structure for agents, strategy resources, analytics, prompts, and skills.

## Resource README and catalog metadata

Every catalog resource needs a `README.md` that explains what the resource does and how to install or use it. Start from [TEMPLATE-README.md](TEMPLATE-README.md).

The README must begin with YAML front matter that follows [the catalog metadata schema](docs/CATALOG-METADATA.md). The catalog uses this metadata for cards and detail pages. In particular:

- Keep `summary` at 140 characters or fewer.
- Write concrete `whatItIs`, `whyUseIt`, and `howToUse` content based on the resource.
- Use `status: preview` for resources that are not production-ready and `status: archived` for retained historical resources.
- Never edit `catalog.json` or the site resource list by hand.

## Authorship

- Set `author` to the original author, a list of authors, or `Microsoft FastTrack` for a team-owned resource.
- When an update adds substantial work by another contributor, add that contributor to the `author` list.
- Do not replace existing authors when adding a co-author.
- Git commit and pull-request history remain the authoritative authorship and version audit trail.

## Versioning

Resources use [Semantic Versioning](https://semver.org/) in `MAJOR.MINOR.PATCH` form:

- **PATCH** (`1.0.0` → `1.0.1`): bug fixes, corrections, and documentation-only changes.
- **MINOR** (`1.0.0` → `1.1.0`): new backward-compatible capabilities or meaningful enhancements.
- **MAJOR** (`1.0.0` → `2.0.0`): breaking changes, incompatible behavior, or a substantial rewrite.

For every resource change:

1. Bump `version`.
2. Set `updated` to the date of the change.
3. Keep `published` as the original publication date.
4. For non-trivial resources, add or update a `CHANGELOG.md` in the resource folder.

## How the catalog updates

The catalog is generated from README front matter:

1. A pull-request workflow runs `npm run check` in `tools/catalog-build` and reports all invalid metadata.
2. After merge to `master`, the workflow regenerates `catalog.json` and its static-site copy.
3. The catalog site fetches that generated JSON at runtime.

Contributors update only their resource files. The workflow handles the catalog output.

## Pull request checklist

- [ ] The change contains no private, customer-specific, or unlicensed content.
- [ ] The resource is in the correct slug-cased folder and has a complete README.
- [ ] README front matter passes the [metadata schema](docs/CATALOG-METADATA.md).
- [ ] `author` includes the original author and any substantial co-authors.
- [ ] `version` and `updated` were bumped; `published` was preserved for updates.
- [ ] Installation and usage steps were tested.
- [ ] `CHANGELOG.md` was updated when appropriate.
- [ ] The pull request contains one focused contribution.

## Tools

Tools are compiled applications or projects larger than a script. They generally belong in their own repository. Open an issue before adding a new tool.

## Bug fixes

Open or reference an issue describing the bug and include enough detail for reviewers to reproduce and test the fix.
