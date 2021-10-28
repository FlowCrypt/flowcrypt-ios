const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

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
        wdaLaunchTimeout: 600000,
        wdaConnectionTimeout: 600000,
        wdaStartupRetries: 4,
        wdaStartupRetryInterval: 120000,
        resetOnSessionStartOnly: true
    },
];

exports.config = config;
