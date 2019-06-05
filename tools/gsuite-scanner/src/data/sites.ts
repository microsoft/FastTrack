import { GetCredentialsDelegate } from "../auth";
import fetch from "../fetch";
import { parseString } from "xml2js";

export interface ISite {
    id: string;
    links: { rel: string, type: string, href: string }[];
    siteName: string;
    theme: string;
    title: string;
    updated: Date;
}

// returns a function binding that allows us to load sites for a given domain
export default (getCreds: GetCredentialsDelegate) => async (domain: string): Promise<ISite[]> => {

    const creds = await getCreds(["https://sites.google.com/feeds"]);

    const response = await fetch(`https://sites.google.com/feeds/site/${domain}/?include-all-sites=true&max-results=100`, {
        headers: {
            "Authorization": `${creds.token_type} ${creds.access_token}`,
            "Gdata-version": "1.4",
        },
        method: "GET",
    });

    if (!response.ok) {
        throw Error(`Error retrieving sites: [${response.status}] ${response.statusText}`);
    }

    const xml = await response.text();

    // now we need to translate the raw response into something useful
    const parsed: ISite[] = await new Promise<ISite[]>((resolve, reject) => {

        parseString(xml, (err, result) => {

            if (err) {
                reject(err);
            }

            // here we need to translate the raw json from xml response into what we care about

            // TODO:: if we have a next we need to process it too
            const next = (<any[]>result.feed.link).filter((node: any) => node.$.rel === "next")[0];

            const sites: ISite[] = (<any[]>result.feed.entry).map((node: any) => {

                return {
                    id: node.id[0],
                    links: (<any[]>node.link).map(n => ({ rel: n.$.rel, type: n.$.type, href: n.$.href })),
                    siteName: node["sites:siteName"][0],
                    theme: node["sites:theme"][0],
                    title: node.title[0],
                    updated: new Date(node.updated[0]),
                };
            });

            resolve(sites);
        });
    });

    return parsed;
};
