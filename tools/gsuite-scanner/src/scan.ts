import { IConfigSchema } from "./config-schema";
import getSitesBinder, { ISite } from "./data/sites";
import { getCredentialsBinder } from "./auth";

export interface IScanResult {
        sites: ISite[];
}

export default async function (config: IConfigSchema): Promise<IScanResult> {

        // create a function binding to get credentials when we need them
        const getCredentials = getCredentialsBinder(config);

        // await getAuthorizedClient(["https://sites.google.com/feeds", "https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file"]);

        // load sites
        const sites = await getSitesBinder(getCredentials)(config.domain);

        // we also need to then augment each site with additional data, extending the object interface each time



        return {
                sites,
        };
}
