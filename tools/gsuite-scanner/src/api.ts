import scan, { IScanResult } from "./scan";
import { IConfigSchema, sanitizeConfig } from "./configuration";

export function gscan(config: Partial<IConfigSchema>): Promise<IScanResult> {

    return scan(sanitizeConfig(config));
}
