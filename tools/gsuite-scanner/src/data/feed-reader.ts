import { Credentials } from "google-auth-library";
import { parseString } from "xml2js";
import fetch from "../fetch";
import { log } from "../log";
import { LogLevel } from "@pnp/logging-commonjs";

/**
 * Reads a feed created with the createFeedReader factory
 * 
 * @param feed 
 */
export async function read<T>(feed: AsyncIterableIterator<T[]>): Promise<T[]> {

    log("Reading feed");

    const results: T[] = [];
    let r: IteratorResult<T[]> = null;

    while (!(r = await feed.next()).done) {
        results.push(...r.value);
    }

    log(`Finished reading feed with ${results.length} results`);

    return results;
}

/**
 * Creates a generator function that will fully read a feed in pages
 *  
 * @param creds The credentials to use for the requests
 * @param parser The parser used to translate the entries into values of T
 */
export function createFeedReader<T>(creds: Credentials, parser: (entry: any) => T): (url: string) => AsyncIterableIterator<T[]> {

    const { token_type, access_token } = creds;

    /**
     * Intakes the intial url of the feed to read, then uses the next link to read the entire results graph
     * translating the results via the supplied parser in the parent function closure
     */
    return async function* (url: string): AsyncIterableIterator<T[]> {

        while (typeof url !== "undefined") {

            log(`Making request to url ${url}`, LogLevel.Verbose);

            const response = await fetch(url, {
                headers: {
                    "Authorization": `${token_type} ${access_token}`,
                    "Gdata-version": "1.4",
                },
                method: "GET",
            });

            if (!response.ok) {

                const body = await response.text();
                throw Error(`Error retrieving sites: [${response.status}] ${response.statusText} (${body})`);
            }

            const xml = await response.text();

            // now we need to translate the raw response into something useful
            yield await new Promise<T[]>((resolve, reject) => {

                parseString(xml, (err, result) => {

                    if (err) {
                        reject(err);
                    }

                    // here we need to translate the raw json from xml response into what we care about
                    const _next = (<any[]>result.feed.link).filter((node: any) => node.$.rel === "next")[0];
                    url = _next ? _next.$.href : undefined;

                    resolve((<any[]>result.feed.entry).map(parser));
                });
            });
        }
    };
}
