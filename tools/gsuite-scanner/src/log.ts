import { Logger, LogLevel, ConsoleListener, FunctionListener, ILogEntry } from "@pnp/logging-commonjs";
import { performance } from "perf_hooks";
import { IConfigSchema } from "./configuration";
import { isFunc, stringIsNullOrEmpty } from "@pnp/common-commonjs";
import { createWriteStream } from "fs";
import { EOL } from "os";

let start = -1;
let end = -1;

function createFileLogger(fileName: string) {

    const fileStream = createWriteStream(fileName, { flags: "a", autoClose: true });

    return function fileLogger(entry: ILogEntry) {

        fileStream.write(entry.message + EOL);
    };
}

export function startLogging(config: IConfigSchema): void {

    // setup logging based on supplied config
    if (config.useDefaultLogging) {
        Logger.subscribe(new ConsoleListener());
    }

    if (isFunc(config.loggingListener)) {
        Logger.subscribe({ log: config.loggingListener });
    }

    if (!stringIsNullOrEmpty(config.logFileName)) {
        Logger.subscribe(new FunctionListener(createFileLogger(config.logFileName)));
    }

    Logger.activeLogLevel = config.verbose ? LogLevel.Verbose : LogLevel.Info;

    startTimer();

    log("Log begins");
}

export function endLogging(): void {

    stopTimer();

    log("Log ends");

    Logger.clearSubscribers();
}

export function startTimer(): void {
    start = performance.now();
}

export function stopTimer(): void {
    end = performance.now();
}

export function log(message: string, level: LogLevel = LogLevel.Info): void {

    const elapsed = (end > 0 ? end : performance.now()) - start;

    Logger.log({
        level,
        message: `[${elapsed.toFixed(2)}] ${message}`,
    });
}

export function logError(err: Error): void {

    const elapsed = (end > 0 ? end : performance.now()) - start;

    Logger.log({
        data: { error: err },
        level: LogLevel.Error,
        message: `[${elapsed.toFixed(2)}] ${err.message} :: stack ::> ${err.stack}`,
    });
}
