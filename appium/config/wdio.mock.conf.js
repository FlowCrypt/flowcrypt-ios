const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
  all: [
    './tests/specs/mock/**/*.spec.ts'
  ],
};

config.capabilities = [
  {
    platformName: 'iOS',
    iosInstallPause: 5000,
    deviceName: 'iPhone 13',
    platformVersion: '15.3',
    automationName: 'XCUITest',
    app: join(process.cwd(), './FlowCrypt.app'),
    processArguments: { 'args': ['--mock-fes-api', '--mock-attester-api'] },
    newCommandTimeout: 10000,
    wdaLaunchTimeout: 300000,
    wdaConnectionTimeout: 600000,
    wdaStartupRetries: 4,
    wdaStartupRetryInterval: 120000,
  },
];

exports.config = config;
