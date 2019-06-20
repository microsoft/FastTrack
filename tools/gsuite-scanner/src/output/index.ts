import { IScanResult } from "../scan";
import { IConfigSchema } from "src/configuration";
import { outputJSON } from "./json";
import { outputCSV } from "./csv";

export interface IOutputDelegate {
    (result: IScanResult): Promise<void>;
}

export async function writeOutput(config: IConfigSchema, result: IScanResult): Promise<void> {

    // map the output strings to output delegates
    // pattern after: https://stackoverflow.com/questions/1960473/get-all-unique-values-in-a-javascript-array-remove-duplicates
    const outputs: IOutputDelegate[] = config.output.filter((v, i, s) => s.indexOf(v) === i).map(v => {

        switch (v) {
            case "json":
                return outputJSON;
            case "csv":
                return outputCSV;
        }
    });

    await Promise.all(outputs.map(v => v(result)));
}
