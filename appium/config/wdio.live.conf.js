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
      deviceName: 'iPhone 11 Pro',
      platformVersion: '16.0',
      app: join(process.cwd(), './FlowCrypt.app'),
    },
  },
];

exports.config = config;
