const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

process.on('unhandledRejection', (reason, promise) => {
    // without this, after lib update to v7, whole test suite may pass even if no tests ran successfully
    console.error('Force-quitting node process because unhandled rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

config.suites = {
    all: [
        './tests/specs/**/*.spec.ts'
    ],
    smoke: [
        './tests/specs/login/GmailLogin.spec.ts'
    ],
    settings: [
        './tests/specs/settings/*.spec.ts'
    ],
    inbox: [
        './tests/specs/inbox/*.spec.ts'
    ],
    draft: [
        './tests/specs/draft/*.spec.ts'
    ]
};

config.capabilities = [
    {
        platformName: 'iOS',
        iosInstallPause: 5000,
        deviceName: 'iPhone 13',
        platformVersion: '15.0',
        automationName: 'XCUITest',
        app: join(process.cwd(), './FlowCrypt.app'),
        newCommandTimeout: 10000,
        wdaLaunchTimeout: 300000,
        wdaConnectionTimeout: 600000,
        wdaStartupRetries: 4,
        wdaStartupRetryInterval: 120000
    },
];

exports.config = config;
