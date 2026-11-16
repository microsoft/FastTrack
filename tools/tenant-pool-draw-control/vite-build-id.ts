/* Build id for the query cache (src/lib/query-cache.ts).
 *
 * `import buildId from "virtual:aether-build-id"` yields a string that is new
 * for every `vite build` (so every publish) and, in the dev server, after every
 * change under `src/`, so a page reloaded after an edit never restores results
 * saved by the code before the edit. The module is invalidated, not hot-updated:
 * an edit triggers no extra reload, and the next page load reads the new id.
 */
import { randomUUID } from "node:crypto";
import path from "node:path";
import type { Plugin } from "vite";

export const BUILD_ID_MODULE = "virtual:aether-build-id";
export const RESOLVED_BUILD_ID_MODULE = `\0${BUILD_ID_MODULE}`;

export function newBuildId(): string {
  return `${Date.now().toString(36)}-${randomUUID()}`;
}

function isUnder(file: string, dir: string): boolean {
  const relative = path.relative(dir, path.resolve(file));
  return (
    relative !== "" &&
    relative !== ".." &&
    !relative.startsWith(`..${path.sep}`) &&
    !path.isAbsolute(relative)
  );
}

export function aetherBuildId(createId: () => string = newBuildId): Plugin {
  let id = createId();
  let root = process.cwd();
  return {
    name: "aether-build-id",
    configResolved(config) {
      root = config.root;
    },
    resolveId(source) {
      return source === BUILD_ID_MODULE ? RESOLVED_BUILD_ID_MODULE : undefined;
    },
    load(source) {
      return source === RESOLVED_BUILD_ID_MODULE
        ? `export default ${JSON.stringify(id)};\n`
        : undefined;
    },
    configureServer(server) {
      const sourceDir = path.join(root, "src");
      const bump = (file: string) => {
        if (!isUnder(file, sourceDir)) return;
        id = createId();
        const mod = server.moduleGraph.getModuleById(RESOLVED_BUILD_ID_MODULE);
        if (mod) server.moduleGraph.invalidateModule(mod);
      };
      server.watcher.on("change", bump);
      server.watcher.on("add", bump);
      server.watcher.on("unlink", bump);
    },
  };
}
