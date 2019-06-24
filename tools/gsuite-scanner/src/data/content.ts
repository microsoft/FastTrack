import { GetCredentialsDelegate } from "../auth";
import { IConfigSchema } from "../configuration";
import { createFeedReader, read } from "./feed-reader";
import { ISite } from "./sites";
import { log } from "../log";

export interface ISiteContent {
    id: string;
    links: { rel: string, type: string, href: string }[];
    pageName: string;
    title: string;
    category: string;
    updated: Date;
    author: { name: string, email: string };
}

export interface ISiteContentSummary {
    count: number;
    lastModified: Date;
    categories: { name: string, count: number }[];
}

export interface ISiteWithContentSummary extends ISite {
    contentSummary: ISiteContentSummary;
}

/**
 * returns a function binding that allows us to load sites for a given domain
 */
export default (getCreds: GetCredentialsDelegate) => async (config: IConfigSchema, siteName: string): Promise<ISiteContent[]> => {

    log(`Reading content for site ${siteName}`);

    const creds = await getCreds(["https://sites.google.com/feeds"]);

    const siteContentFeedReader = createFeedReader<ISiteContent>(creds, (node: any) => ({
        author: node.author[0],
        category: node.category[0].$.label,
        id: node.id[0],
        links: (<any[]>node.link).map(n => ({ rel: n.$.rel, type: n.$.type, href: n.$.href })),
        pageName: node["sites:pageName"] ? node["sites:pageName"][0] : "",
        title: node.title[0],
        updated: new Date(node.updated[0]),
    }));

    const baseUrl = `https://sites.google.com/feeds/content/${config.domain}/${siteName}`;
    const params = [
        `max-results=${config.maxResultsPerPage}`,
        // fields not currently supported
        // "fields=link[@rel='next'],entry(id,published,updated,title,category,link)",
    ];

    return read(siteContentFeedReader(`${baseUrl}?${params.join("&")}`));
};

export function summarize(site: ISite, content: ISiteContent[]): ISiteWithContentSummary {

    const lastUpdated = content.map(c => c.updated).reduce((prev, cur) => cur > prev ? cur : prev, new Date(0));

    const cats = content.map(c => c.category).reduce((prev, cur) => {
        const index = prev.findIndex(i => i.name === cur);
        if (index < 0) {
            prev.push({ name: cur, count: 1 });
        } else {
            prev[index].count++;
        }
        return prev;
    }, <{ name: string, count: number }[]>[]);

    // augment the site with the summary information
    return Object.assign(site, {
        contentSummary: {
            categories: cats,
            count: content.length,
            lastModified: lastUpdated,
        },
    });
}
