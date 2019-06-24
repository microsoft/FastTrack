import { IScanResult } from "src/scan";
import { EOL } from "os";
import { createWriteStream, WriteStream } from "fs";

export async function outputCSV(result: IScanResult, fileName = "gscan_results.csv"): Promise<void> {

    const fileStream = createWriteStream(fileName, { flags: "a", autoClose: false });

    // write headers
    const headers = [
        "id",
        "siteName",
        "theme",
        "title",
        "updated",
        "content-count",
        "content-last-modified",
        "content-categories",
    ].join(",");

    await doWrite(fileStream, headers + EOL);

    for (let i = 0; i < result.sites.length; i++) {

        const site = result.sites[i];

        const data = [
            `'${site.id}'`,
            `'${site.siteName}'`,
            `'${site.theme}'`,
            `'${site.title}'`,
            `'${site.updated}'`,
            `${site.contentSummary.count}`,
            `'${site.contentSummary.lastModified}'`,
            `'${site.contentSummary.categories.map(cat => `${cat.name}:${cat.count}`).join(";")}'`,
        ].join(",");

        await doWrite(fileStream, data + EOL);
    }

    fileStream.close();
}

function doWrite(stream: WriteStream, value: string): Promise<void> {

    return new Promise<void>((resolve, reject) => {

        stream.write(value, (err) => {

            if (err) {
                reject(err);
            }

            resolve();
        });
    });
}
