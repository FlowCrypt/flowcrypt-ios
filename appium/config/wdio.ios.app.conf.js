const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
    all: [
        './tests/specs/**/*.spec.ts'
    ],
    smoke: [
        './tests/specs/login/GmailLogin.spec.ts',
        './tests/specs/inbox/ReadTextEmail.spec.ts',
        './tests/specs/composeEmail/CheckComposeEmailAfterReopening.spec.ts',
    ]
};

config.capabilities = [
    {
        platformName: 'iOS',
        iosInstallPause: 5000,
        deviceName: 'iPhone 11 Pro Max',
        platformVersion: '15.0',
        automationName: 'XCUITest',
        app: join(process.cwd(), './apps/FlowCrypt.app'),
        newCommandTimeout: 10000,
        wdaLaunchTimeout: 300000,
        wdaConnectionTimeout: 600000,
        wdaStartupRetries: 4,
        wdaStartupRetryInterval: 120000,
        resetOnSessionStartOnly: true
    },
];

exports.config = config;
