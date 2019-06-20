import { IConfigSchema } from "./configuration";
import getSitesBinder from "./data/sites";
import { getCredentialsBinder } from "./auth";
import { startLogging, endLogging } from "./log";
import { sanitizeConfig } from "./configuration";
import getContentBinder, { summarize, ISiteWithContentSummary } from "./data/content";
import { writeOutput } from "./output";

export interface IScanResult {
    sites: ISiteWithContentSummary[];
}

/**
 * This function conducts a scan based on the supplied configuration
 * 
 * @param config 
 */
export default async function (config: IConfigSchema): Promise<IScanResult> {

    // ensure we have good configuration
    config = sanitizeConfig(config);

    startLogging(config);

    // create a function binding to get credentials when we need them
    const getCredentials = getCredentialsBinder(config);

    // load all sites
    const sites = await getSitesBinder(getCredentials)(config);

    const sitesWithSummary: ISiteWithContentSummary[] = [];

    // add content summary to all sites
    for (let i = 0; i < sites.length; i++) {
        const site = sites[i];
        const content = await getContentBinder(getCredentials)(config, site.siteName);
        sitesWithSummary.push(summarize(site, content));
    }

    const result = {
        sites: sitesWithSummary,
    };

    // now we need to output our stuff to the configured outputs
    writeOutput(config, result);

    endLogging();

    return result;
}
