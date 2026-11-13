import { readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import type { Plugin } from "vite";

// @microsoft/managed-apps before 0.5.12 builds every shared_sql (SQL Server
// connector) action URL as `.../datasets/{dataset}/procedures/{path}`. Swagger
// operations that carry their own path template, such as
// ExecutePassThroughNativeQuery_V2 (`/{connectionId}/v2/datasets/{server},{database}/query/sql`),
// end up at a malformed URL the connector answers with 404. 0.5.12 takes the
// procedures shortcut only for operations without path parameters and honours
// `datasetNameOverride`; this plugin applies that change to the installed SDK,
// in the dev pre-bundle and in the publish build. One guard is added: an
// operation with no `parameters` metadata keeps the procedures shortcut 0.5.11
// gave it instead of throwing. Bumping the SDK instead would also change the
// image/* result shape existing apps read.
//
// The patch is version-pinned: it applies only when the connectorExecutor.js
// being loaded belongs to managed-apps-common PATCHED_COMMON_VERSION (the one
// 0.5.11 ships), read from that package's own package.json. Any other version,
// 0.5.12's 0.20.0 included, is loaded untouched, so an SDK upgrade retires the
// patch without an edit here. On the pinned version, a connectorExecutor.js that
// does not end up with both halves fixed fails the build, in dev and in publish
// alike, rather than shipping SQL calls that 404 or ignore datasetNameOverride.
// The image build's template tests (.aether-container-tests/sdk-sqlfix.test.ts)
// assert the installed SDK is either the pinned version and patches, or another
// version that no longer carries the 0.5.11 rule: an upgrade to a version that
// still has the bug fails the image build until this file covers it.
//
// Template scaffold file: it is copied into an app when the app is created.
// Existing apps are not refreshed with it on reopen
// (`aether_orch_appdev::provision::refresh_existing_app` refreshes only the
// dev-reload client and the parent transport). That is why the plugin is
// registered in the app's vite.config.ts, not injected by the image-side
// overlay (aether.vite.config.mts) like the dev-reload plugins: the overlay
// serves existing apps too, and the patch ships only with apps created with
// this file. vite.config.ts and this file are protected scaffold files.

// The managed-apps-common version that @microsoft/managed-apps 0.5.11 ships
// connectorExecutor.js in. Only that exact version is patched; any other
// version is loaded untouched.
export const PATCHED_COMMON_VERSION = "0.19.0";

export const TARGET =
  /[\\/]@microsoft[\\/]managed-apps-common[\\/]dist[\\/]dataClient[\\/]data[\\/]connectorExecutor\.js$/;

const URL_BUG =
  /const path = dataSourceInfo\.apis\[operationName\]\.path;(\s*)if \(isSharedSql\) \{/;
const URL_FIX =
  "const api = dataSourceInfo.apis[operationName];$1const path = api.path;$1" +
  "const hasPathParameters = (api.parameters || []).some((parameter) => parameter.in === 'path');$1" +
  "if (isSharedSql && !hasPathParameters) {";
const URL_FIXED = /if \(isSharedSql && !hasPathParameters\) \{/;

const DATASET_BUG = /datasetName: connectionReference\.datasetName \?\? '',/;
const DATASET_FIX =
  "datasetName: connectionReference.datasetNameOverride?.trim() || connectionReference.datasetName || '',";
const DATASET_FIXED =
  /datasetName: connectionReference\.datasetNameOverride\?\.trim\(\) \|\| connectionReference\.datasetName \|\| '',/;

// Each half of the fix: the 0.5.11 shape, the shape it has once fixed (by this
// patch or upstream in 0.5.12), and its replacement.
const FIXES = [
  { bug: URL_BUG, fixed: URL_FIXED, fix: URL_FIX },
  { bug: DATASET_BUG, fixed: DATASET_FIXED, fix: DATASET_FIX },
];

export const UNPATCHABLE =
  "[aether-sdk-sqlfix] @microsoft/managed-apps connectorExecutor.js is in neither the 0.5.11 shape " +
  "this patch rewrites nor the fixed 0.5.12 shape; failing the build rather than shipping SQL Server " +
  "connector calls that may 404. Update aether-sdk-sqlfix.ts for the installed SDK.";

function occurrences(code: string, pattern: RegExp): number {
  return code.match(new RegExp(pattern.source, "g"))?.length ?? 0;
}

/**
 * `code` with both halves of the shared_sql fix (operation URL rule and
 * `datasetNameOverride`) applied; `code` itself when both are already present;
 * `null` when either half is not in exactly one known shape, so the SDK is
 * never left half patched.
 */
export function patchConnectorExecutor(code: string): string | null {
  let patched = code;
  for (const { bug, fixed, fix } of FIXES) {
    const bugs = occurrences(code, bug);
    const fixes = occurrences(code, fixed);
    if (bugs === 1 && fixes === 0) {
      patched = patched.replace(bug, fix);
    } else if (bugs !== 0 || fixes !== 1) {
      return null;
    }
  }
  return patched;
}

/** True when `code` still has the 0.5.11 shared_sql URL or datasetName rule. */
export function carriesSqlBug(code: string): boolean {
  return FIXES.some(({ bug }) => occurrences(code, bug) > 0);
}

/**
 * The `version` of the managed-apps-common package that `file` (its
 * connectorExecutor.js) belongs to, read from that package's own
 * package.json; `null` when it cannot be read.
 */
export function packageVersionOf(file: string): string | null {
  const root = file.replace(/[\\/]dist[\\/]dataClient[\\/]data[\\/]connectorExecutor\.js$/, "");
  try {
    const version: unknown = JSON.parse(readFileSync(path.join(root, "package.json"), "utf8")).version;
    return typeof version === "string" ? version : null;
  } catch {
    return null;
  }
}

export interface SqlFixOptions {
  /** Version lookup for a connectorExecutor.js path; tests replace it. */
  versionOf?: (file: string) => string | null;
}

export default function aetherSdkSqlFix({ versionOf = packageVersionOf }: SqlFixOptions = {}): Plugin {
  const applies = (file: string) => versionOf(file) === PATCHED_COMMON_VERSION;
  return {
    name: "aether-sdk-sqlfix",
    enforce: "pre",
    config() {
      // Dev pre-bundling runs esbuild over node_modules and never calls Vite's
      // `transform`, so the patch is applied there as well.
      return {
        optimizeDeps: {
          esbuildOptions: {
            plugins: [
              {
                name: "aether-sdk-sqlfix",
                setup(build) {
                  build.onLoad({ filter: TARGET }, async (args) => {
                    if (!applies(args.path)) return undefined;
                    const code = await readFile(args.path, "utf8");
                    const patched = patchConnectorExecutor(code);
                    if (patched === null) return { errors: [{ text: UNPATCHABLE }] };
                    return { contents: patched, loader: "js" };
                  });
                },
              },
            ],
          },
        },
      };
    },
    transform(code, id) {
      const file = id.split("?")[0];
      if (!TARGET.test(file) || !applies(file)) return null;
      const patched = patchConnectorExecutor(code);
      if (patched === null) this.error(UNPATCHABLE);
      return patched === code ? null : { code: patched, map: null };
    },
  };
}
