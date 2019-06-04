#!/usr/bin/env node

import * as LiftOff from "liftoff";
import { jsVariants } from "interpret";
import { IConfigSchema, getAuthorizedClient } from "../";
import * as findup from "findup-sync";
import { Scanner } from "../src/scanner";

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
    const credsPath = findup(config.default.credentialPath);
    const creds = await import(credsPath);

    console.log(`GScan Version: ${pkg.version}`);
    console.log(`Domain: ${config.default.domain}`);
    console.log(`Impersonating: ${config.default.impersonatingAccount}`);
    console.log(`Credentials path: ${config.default.credentialPath}`);


    const scanner = new Scanner(config.default);

    

});
