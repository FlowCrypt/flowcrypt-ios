const { join } = require('path');
const { config } = require('./wdio.shared.conf');

config.suites = {
    all: [
        './tests/specs/**/*.spec.ts'
    ],
    smoke: [
        './tests/specs/inbox/inbox.spec.ts',
    ]
};

config.capabilities = [
    {
        platformName: 'iOS',
        iosInstallPause: 5000,
        deviceName: process.env.DEVICE_MODEL || 'iPhone 11 Pro Max',
        platformVersion: '14.5',
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
