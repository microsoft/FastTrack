import { default as fetch, RequestInit, Response } from "node-fetch";
import { HttpsProxyAgent } from "https-proxy-agent";
import { stringIsNullOrEmpty } from "@pnp/common-commonjs";

let enableProxy = false;
let proxyUrl: string | null = null;

export function setProxyUrl(url: string): void {
    proxyUrl = url;
    enableProxy = true;
}

export function useProxy(v: boolean): void {
    enableProxy = v;
}

// wrapper in case we need to update this functionality
export default function (url: string, options: RequestInit): Promise<Response> {

    if (enableProxy && !stringIsNullOrEmpty(proxyUrl)) {
        options.agent = new HttpsProxyAgent(proxyUrl);
    }

    return fetch(url, options);
}
