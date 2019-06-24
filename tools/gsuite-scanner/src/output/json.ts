import { IScanResult } from "src/scan";
import { writeFile } from "fs";

export function outputJSON(result: IScanResult, fileName = "gscan_results.json"): Promise<void> {

    return new Promise((resolve, reject) => {

        writeFile(fileName, JSON.stringify(result, null, 2), (err) => {

            if (err) {
                return reject(err);
            }

            resolve();
        });
    });
}
