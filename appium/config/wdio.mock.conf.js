const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
  all: [
    './tests/specs/mock/**/*.spec.ts'
  ]
};

config.capabilities = [
  {
    platformName: 'iOS',
    iosInstallPause: 5000,
    deviceName: 'iPhone 13',
    platformVersion: '15.5',
    automationName: 'XCUITest',
    // app: join(process.cwd(), './FlowCrypt.app'),
    // processArguments: { 'args': ['--mock-fes-api', '--mock-attester-api', '--mock-gmail-api'] },
    newCommandTimeout: 10000,
    wdaLaunchTimeout: 30000,
    wdaConnectionTimeout: 60000,
    wdaStartupRetries: 1,
    wdaStartupRetryInterval: 12000,
  },
];

exports.config = config;
