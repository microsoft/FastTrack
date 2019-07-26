# Google Site Scanner

The Google Site Scanner (gscan) cli tool allows you to gather basic statistics around existing v1 Google Sites. These include number of sites, types of content, and last updated values.

## Install

### Prerequisites

- [nodejs >= 10](https://nodejs.org)

### Installation

`npm install -g @microsoft/gscan`

## Setup

### Create Google Service Account (one-time)

1. Create a service account in your Google tenant
2. Grant that account permissions to use the "https://sites.google.com/feeds" scope
3. Download the client configuration file and save it as "credentials.json" into the app working directory

### Create configuration file (one-time)

The behavior of the cli tool is controlled by a JavaScript configuration file named `gscan-config.js`. This allows you some flexibility as you can use code in the configuration. This file should be located in your app working directory and be named `gscan-config.js`. The application expects a single export with the following structure. "credentialPath", "domain", and "impersonatingAccount" are required, the rest are optional.

```JavaScript
{
    credentialPath: string,
    domain: string,
    impersonatingAccount: string,
    maxResultsPerPage: 100,
    output: ["csv", "json"],
    verbose: boolean,
    loggingListener: (entry: {}) => void,
    useDefaultLogging: boolean,
    logFileName: string,
    proxyUrl: string,
}
```

**Example Configuration File**

Minimal:
```JavaScript
module.exports = {
    credentialPath: "./credentials.json",
    domain: "mydomain.com",
    impersonatingAccount: "admin@mydomain.com"
};
```

Extended:
```JavaScript
module.exports = {
    credentialPath: "./credentials.json",
    domain: "mydomain.com",
    impersonatingAccount: "admin@mydomain.com",
    maxResultsPerPage: 25,
    output: ["json", "csv"],
    verbose: true,
    loggingListener: (entry) => console.log(entry.message),
    useDefaultLogging: false,
    logFileName: "mylog.txt",
    proxyUrl: "https://my.proxy.url",
};
```

Suppress log file:
```JavaScript
module.exports = {
    credentialPath: "./credentials.json",
    domain: "mydomain.com",
    impersonatingAccount: "admin@mydomain.com",
    logFileName: "",
};
```

|Option|Description|
|--|--|
|credentialPath|Path relative to the working directory where the Google credentials file can be found|
|domain|The Google domain to scan. The tool can process a single domain at a time|
|impersonatingAccount|The account the app will impersonate, must have access to all of the sites you want to scan.=|
|maxResultsPerPage|[Optional, default 100] Controls the page size when reading feeds|
|output|[Optional, default "json"] Controls what output is generated. Array of "json" or "csv"|
|verbose|[Optional, default false] If true extended information will be included in the logs|
|loggingListener|[Optional, default null] Allows you to supply an additional logging function that will receive all logging messages. Function takes a single argument and returns null. The argument will be `{ message: string, level: 0|1|2|3|99, data: any }`. 0 = Verbose|
|useDefaultLogging|[Optional, default true] If true logging is also written to the console.|
|logFileName|[Optional, default 'gscan_log_{timestamp}.txt'] Name of the log file, set to empty string to supress log file generation.|
|proxyUrl|[Optional]Url to a network proxy (added in 0.0.3)|

###

1. Open a command prompt to the folder where you saved the credentials and configuration file
2. Run `gscan`

# Build

To build the solution execute:

```CMD
npm run build
```

# Publish

To publish a new version you need to increment the version number appropriately and then publish the solution. The publish command handles rebuilding the solution.

```CMD
npm version patch
npm publish
```

# Debug

If you are using VS Code F5 debugging is setup. It expects a local folder named "gscan-local-testing" containing the credentials and config files, you can adjust this path in the launch file.

