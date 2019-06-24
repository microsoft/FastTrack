import { GetCredentialsDelegate } from "../auth";
import { IConfigSchema } from "../configuration";
import { read, createFeedReader } from "./feed-reader";
import { log } from "../log";

export interface ISite {
    id: string;
    links: { rel: string, type: string, href: string }[];
    siteName: string;
    theme: string;
    title: string;
    updated: Date;
}

/**
 * returns a function binding that allows us to load sites for a given domain
 */
export default (getCreds: GetCredentialsDelegate) => async (config: IConfigSchema): Promise<ISite[]> => {

    log("Loading all sites...");

    const creds = await getCreds(["https://sites.google.com/feeds"]);

    log("Creating sites feed reader...");

    const sitesFeedReader = createFeedReader<ISite>(creds, (node: any) => ({
        id: node.id[0],
        links: (<any[]>node.link).map(n => ({ rel: n.$.rel, type: n.$.type, href: n.$.href })),
        siteName: node["sites:siteName"][0],
        theme: node["sites:theme"][0],
        title: node.title[0],
        updated: new Date(node.updated[0]),
    }));

    log("Created sites feed reader.");

    const baseUrl = `https://sites.google.com/feeds/site/${config.domain}/`;
    const params = [
        "include-all-sites=true",
        `max-results=${config.maxResultsPerPage}`,
    ];

    log(`Reading sites from feed ${baseUrl}`);

    return read(sitesFeedReader(`${baseUrl}?${params.join("&")}`));
};
