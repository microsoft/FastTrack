import { IConfigSchema } from "./configuration";
import { JWT, Credentials } from "google-auth-library";

export interface IServiceAccountCredentials {
    "type": string;
    "project_id": string;
    "private_key_id": string;
    "private_key": string;
    "client_email": string;
    "client_id": string;
    "auth_uri": string;
    "token_uri": string;
    "auth_provider_x509_cert_url": string;
    "client_x509_cert_url": string;
}

export type GetCredentialsDelegate = (scopes: string[]) => Promise<Credentials>;

export function getCredentialsBinder(config: IConfigSchema): GetCredentialsDelegate {

    return async (scopes: string[]) => {

        const credentialsFromFile: IServiceAccountCredentials = await import(config.credentialPath);

        const client = new JWT(credentialsFromFile.client_email, null, credentialsFromFile.private_key, scopes, config.impersonatingAccount);

        const creds = await client.authorize();

        return creds;
    };
}
