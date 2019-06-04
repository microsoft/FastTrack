import { readFile, writeFile } from "fs";
import * as readline from "readline";
import { google } from "googleapis";
import { default as fetch } from "node-fetch";
import { parseString } from "xml2js";

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

export async function getAuthorizedClient(creds: IServiceAccountCredentials, scopes: string[]): Promise<any> {



    const client = new google.auth.JWT(creds.client_email, null, creds.private_key, scopes, "admin@slobcure.com");

    const credentials = await client.authorize();

    // ?include-all-sites=true&with-mappings=true

    // mimeType="application/vnd.google-apps.site"

    // ?q=mimeType="application/vnd.google-apps.site"

    /* tslint:disable */
    // const url = `https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(`mimeType="application/vnd.google-apps.site"`)}&corpora=allDrives&includeItemsFromAllDrives=true&includeTeamDriveItems=true&supportsAllDrives=true`;

    const url = `https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(`mimeType="application/vnd.google-apps.site"`)}&corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true`;

    // const url2 = "https://www.googleapis.com/drive/v3/files?q=mimeType%3D%22application%2Fvnd.google-apps.site%22&corpora='allDrives'";

    // const url3 = `https://www.googleapis.com/drive/v3/drives`;

    // const url4 = `https://www.googleapis.com/drive/v3/files?fields=*`;

    // const r = await fetch(url, {
    //     headers: {
    //         "Authorization": `${credentials.token_type} ${credentials.access_token}`,
    //     },
    //     method: "GET",
    // });

    const r = await fetch("https://sites.google.com/feeds/site/slobcure.com/?include-all-sites=true&max-results=50", {
        headers: {
            "Authorization": `${credentials.token_type} ${credentials.access_token}`,
            "Gdata-version": "1.4",
        },
        method: "GET",
    });

    const y = await r.text();

    const z = await new Promise((resolve, reject) => {

        parseString(y, (err, result) => {

            if (err) {
                reject(err);
            }

            resolve(result);
        });
    });


    console.log(y);





    return credentials;

    // const url = client.generateAuthUrl({ scope: scopes, access_type: "offline" });

    // console.log("Authorize this app by visiting this url:", url);

    // const rl = readline.createInterface({
    //     input: process.stdin,
    //     output: process.stdout,
    // });

    // const token = await new Promise((resolve, reject) => {

    //     rl.question("Enter the code from that page here: ", (code) => {
    //         rl.close();
    //         client.getToken(code, (err, token2) => {

    //             if (err) {
    //                 reject(err);
    //                 // return console.error("Error retrieving access token", err);
    //             }

    //             resolve(token2);

    //             // ;
    //             // storeToken(token);
    //             // callback(oauth2Client);
    //         });
    //     });

    // });

    // client.credentials = token;

    // return token;
}



    // @ts-ignore
    // const token = await t.getToken()


    // // Load client secrets from a local file.
    // readFile("credentials.json", "utf8", (err, content) => {

    //     if (err) {
    //         return console.error("Error loading client secret file", err);
    //     }

    //     // Authorize a client with the loaded credentials, then call the
    //     // Directory API.
    //     authorize(JSON.parse(content), (_client) => {

    //         console.log("here");
    //     });
    // });


// /**
//  * Create an OAuth2 client with the given credentials, and then execute the
//  * given callback function.
//  *
//  * @param {Object} credentials The authorization client credentials.
//  * @param {function} callback The callback to call with the authorized client.
//  */
// async function authorize(credentials, callback): Promise<any> {

//     const { client_secret, client_id, redirect_uris } = credentials;
//     const oauth2Client = new google.auth.OAuth2(client_id, client_secret, redirect_uris[0]);

//     // Check if we have previously stored a token.
//     readFile(TOKEN_PATH, "utf8", (err, token) => {

//         if (err) {
//             return getNewToken(oauth2Client, callback);
//         }

//         oauth2Client.credentials = JSON.parse(token);

//     });

//     return oauth2Client;
// }

// /**
//  * Get and store new token after prompting for user authorization, and then
//  * execute the given callback with the authorized OAuth2 client.
//  *
//  * @param {google.auth.OAuth2} oauth2Client The OAuth2 client to get token for.
//  * @param {getEventsCallback} callback The callback to call with the authorized
//  *     client.
//  */
// function getNewToken(oauth2Client, callback) {

//     const authUrl = oauth2Client.generateAuthUrl({
//         access_type: "offline",
//         scope: SCOPES,
//     });

//     console.log("Authorize this app by visiting this url:", authUrl);

//     const rl = readline.createInterface({
//         input: process.stdin,
//         output: process.stdout,
//     });

//     rl.question("Enter the code from that page here: ", (code) => {
//         rl.close();
//         oauth2Client.getToken(code, (err, token) => {

//             if (err) {
//                 return console.error("Error retrieving access token", err);
//             }

//             oauth2Client.credentials = token;
//             storeToken(token);
//             callback(oauth2Client);
//         });
//     });
// }

// /**
// * Store token to disk be used in later program executions.
// *
// * @param {Object} token The token to store to disk.
// */
// function storeToken(token) {

//     writeFile(TOKEN_PATH, JSON.stringify(token), (err) => {

//         if (err) {
//             return console.warn(`Token not stored to ${TOKEN_PATH}`, err);
//         }

//         console.log(`Token stored to ${TOKEN_PATH}`);
//     });
// }
