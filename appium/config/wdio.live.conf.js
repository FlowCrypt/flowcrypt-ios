const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
  all: [
    './tests/specs/live/**/*.spec.ts'
  ],
  settings: [
    './tests/specs/live/settings/*.spec.ts'
  ],
  inbox: [
    './tests/specs/live/inbox/*.spec.ts'
  ],
  compose: [
    './tests/specs/live/composeEmail/*.spec.ts'
  ],
  login: [
    './tests/specs/live/login/*.spec.ts'
  ],
  update: [
    './tests/specs/live/update/*.spec.ts'
  ]
};

config.capabilities = [
  {
    platformName: 'iOS',
    iosInstallPause: 5000,
    deviceName: 'iPhone 13',
    platformVersion: '15.4',
    automationName: 'XCUITest',
    app: join(process.cwd(), './FlowCrypt.app'),
    simpleIsVisibleCheck: true,
    newCommandTimeout: 10000,
    wdaLaunchTimeout: 300000,
    wdaConnectionTimeout: 600000,
    wdaStartupRetries: 4,
    wdaStartupRetryInterval: 120000
  },
];

exports.config = config;
