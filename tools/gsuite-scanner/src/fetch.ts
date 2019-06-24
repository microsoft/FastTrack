import { default as fetch, RequestInit, Response } from "node-fetch";

// wrapper in case we need to update this functionality
export default function (url: string, options: RequestInit): Promise<Response> {

    return fetch(url, options);
}
