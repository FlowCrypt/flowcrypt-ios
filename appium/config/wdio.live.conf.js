const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
  all: [
    './tests/specs/live/**/*.spec.ts'
  ]
};

config.capabilities = [
  {
    platformName: 'iOS',
    'appium:automationName': 'XCUITest',
    'appium:options': {
      deviceName: 'iPhone 14',
      platformVersion: '16.0',
      app: join(process.cwd(), './FlowCrypt.app'),
      newCommandTimeout: 10000,
      wdaLaunchTimeout: 300000,
      wdaConnectionTimeout: 600000,
      wdaStartupRetries: 4,
      wdaStartupRetryInterval: 120000,
      iosInstallPause: 5000,
    },
  },
];

exports.config = config;
