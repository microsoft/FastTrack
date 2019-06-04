import { IConfigSchema } from "./config-schema";

export class Scanner {

    constructor(private _config: IConfigSchema) {

        

    // await getAuthorizedClient(["https://sites.google.com/feeds", "https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file"]);



    }

    public async scan(): Promise<void> {

        

    }
}

