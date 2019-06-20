#!/usr/bin/env node

import * as LiftOff from "liftoff";
import { jsVariants } from "interpret";
import { IConfigSchema } from "../src/configuration";
import * as findup from "findup-sync";
import scan from "../src/scan";
import { resolve } from "path";
import { log, logError} from "../src/log";

const packagePath = findup("package.json");

const scanner = new LiftOff({
    configName: "gscan-config",
    extensions: jsVariants,
    name: "gscan",
});

scanner.launch({}, async (env: LiftOff.LiftoffEnv) => {

    console.clear();

    if (typeof env.configPath === "undefined" || env.configPath === null || env.configPath === "") {
        throw Error("No config file found.");
    }

    const config: { default: IConfigSchema } = await import(env.configPath);
    const pkg: { version: string } = await import(packagePath);

    // ensure we correctly resolve our credential file path relatice to the config base path
    config.default.credentialPath = resolve(env.configBase, config.default.credentialPath);

    console.log(`gscan Version: ${pkg.version}`);

    if (config.default.verbose) {
        // dump config values
        const keys = Object.getOwnPropertyNames(config.default);
        for (let i = 0; i < keys.length; i++) {
            log(`${keys[i]} = ${config.default[keys[i]]}`);
        }
    }

    try {

        const results = await scan(config.default);

        log(`Scan complete, processed ${results.sites.length} sites.`);

    } catch (e) {
        logError(e);
    }
});
