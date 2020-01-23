import { stringIsNullOrEmpty } from "@pnp/common-commonjs";
import { existsSync } from "fs";
import { setProxyUrl } from "./fetch";

export interface IConfigSchema {
    domain: string;
    credentialPath: string;
    impersonatingAccount: string;
    verbose: boolean;
    maxResultsPerPage: number;
    loggingListener: (entry: {}) => void;
    useDefaultLogging: boolean;
    logFileName: string;
    output: ("json" | "csv")[];
    proxyUrl: string | null;
}

export function sanitizeConfig(config: Partial<IConfigSchema>): IConfigSchema {

    const d = new Date();

    const saneConfig = Object.assign<IConfigSchema, Partial<IConfigSchema>>({
        credentialPath: "",
        domain: "",
        impersonatingAccount: "",
        logFileName: `gscan_log_${d.getFullYear()}${d.getMonth()}${d.getDay()}${d.getHours()}${d.getMinutes()}${d.getSeconds()}${d.getMilliseconds()}.txt`,
        loggingListener: null,
        maxResultsPerPage: 100,
        output: ["json"],
        proxyUrl: null,
        useDefaultLogging: true,
        verbose: false,
    }, config);

    // now we validate our configuration
    if (stringIsNullOrEmpty(saneConfig.credentialPath) || !existsSync(saneConfig.credentialPath)) {
        throw Error("You must supply a valid credentialPath in the gscan-config.js file.");
    }

    if (stringIsNullOrEmpty(saneConfig.domain)) {
        throw Error("You must supply a valid domain in the gscan-config.js file.");
    }

    if (stringIsNullOrEmpty(saneConfig.impersonatingAccount)) {
        throw Error("You must supply a valid impersonatingAccount in the gscan-config.js file.");
    }

    if (!stringIsNullOrEmpty(saneConfig.proxyUrl)) {
        setProxyUrl(saneConfig.proxyUrl);
    }

    return saneConfig;
}
