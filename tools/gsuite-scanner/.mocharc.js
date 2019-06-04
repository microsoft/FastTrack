const config = {
    "package": "./package.json",
    "reporter": "spec",
    "slow": 3000,
    "timeout": 40000,
    "ui": "bdd",
    "require": [
        "tsconfig-paths/register",
        "ts-node/register"
    ],
    "spec": [
        "./test/**/*.ts"
    ]
};

module.exports = config;