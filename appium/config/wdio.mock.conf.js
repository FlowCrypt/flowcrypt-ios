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
    "appium:iosInstallPause": 5000,
    "appium:deviceName": 'iPhone 13',
    "appium:platformVersion": '15.4',
    "appium:automationName": 'XCUITest',
    "appium:app": join(process.cwd(), './FlowCrypt.app'),
    "appium:processArguments": { 'args': ['--mock-fes-api', '--mock-attester-api'] },
    "appium:newCommandTimeout": 10000,
    "appium:wdaLaunchTimeout": 300000,
    "appium:wdaConnectionTimeout": 600000,
    "appium:wdaStartupRetries": 4,
    "appium:wdaStartupRetryInterval": 120000,
  },
];

exports.config = config;
