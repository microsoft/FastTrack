#!/usr/bin/env node

import * as LiftOff from "liftoff";
import { jsVariants } from "interpret";
import { IConfigSchema } from "../src/config-schema";
import * as findup from "findup-sync";
import scan from "../src/scan";
import { resolve } from "path";

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
        console.log(`Domain: ${config.default.domain}`);
        console.log(`Impersonating: ${config.default.impersonatingAccount}`);
        console.log(`Credentials path: ${config.default.credentialPath}`);
    }

    try {

        const results = await scan(config.default);

        // obviously we need various outputters
        console.log(JSON.stringify(results, null, 2));

    } catch (e) {

        console.error(e);
    }
});
