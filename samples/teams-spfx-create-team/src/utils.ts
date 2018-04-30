/**
 * Converts a json object to an escaped string appropriate for use in attributes when storing client-side controls
 *
 * @param json The json object to encode into a string
 */
export function jsonToEscapedString(json: any): string {

    return JSON.stringify(json)
        .replace(/"/g, "&quot;")
        .replace(/:/g, "&#58;")
        .replace(/{/g, "&#123;")
        .replace(/}/g, "&#125;");
}

/**
 * Converts an escaped string from a client-side control attribute to a json object
 *
 * @param escapedString
 */
export function escapedStringToJson<T = any>(escapedString: string): T {

    return JSON.parse(escapedString
        .replace(/&quot;/g, `"`)
        .replace(/&#58;/g, ":")
        .replace(/&#123;/g, "{")
        .replace(/&#125;/g, "}"));
}