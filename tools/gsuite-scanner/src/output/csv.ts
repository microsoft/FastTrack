import { IScanResult } from "src/scan";
// import { writeFile } from "fs";

export function outputCSV(_result: IScanResult, _fileName = "gscan_results.json"): Promise<void> {

    return new Promise((resolve, reject) => {

        // // we need to flatten each thing into csv
        // // keeping just the fields we care about


        resolve();
        // writeFile(fileName, JSON.stringify(result, null, 2), (err) => {

        //     if (err) {
        //         return reject(err);
        //     }

        //     resolve();
        // });
    });
}
