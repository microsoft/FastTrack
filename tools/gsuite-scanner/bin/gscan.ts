#!/usr/bin/env node

import * as LiftOff from "liftoff";
import { jsVariants } from "interpret";
import { IConfigSchema } from "../src/configuration";
import scan from "../src/scan";
import { resolve } from "path";
import { log, logError } from "../src/log";

const scanner = new LiftOff({
    configName: "gscan-config",
    extensions: jsVariants,
    name: "gscan",
    processTitle: "gscan",
});

scanner.launch({}, async (env: LiftOff.LiftoffEnv) => {

    console.clear();

    if (typeof env.configPath === "undefined" || env.configPath === null || env.configPath === "") {
        throw Error("No config file found.");
    }

    const config: IConfigSchema = await import(env.configPath);

    // ensure we correctly resolve our credential file path relative to the config base path
    config.credentialPath = resolve(env.configBase, config.credentialPath);

    console.log(`gscan Version: ${env.modulePackage.version}`);

    if (config.verbose) {
        // dump config values
        log("Verbose logging enabled");
        log("Configuration values:");
        const keys = Object.getOwnPropertyNames(config);
        for (let i = 0; i < keys.length; i++) {
            log(`${keys[i]} = ${config[keys[i]]}`);
        }
    }

    try {

        const results = await scan(config);

        log(`Scan complete, processed ${results.sites.length} sites.`);

    } catch (e) {
        logError(e);
    }
});
