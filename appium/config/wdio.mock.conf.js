const { join } = require('path');
const { config } = require('./wdio.shared.conf');
const pathWdioConfig = require('path');
require('dotenv').config({ path: pathWdioConfig.resolve(__dirname, '../.env') });

config.suites = {
  all: [
    './tests/specs/mock/**/*.spec.ts'
  ],
  settings: [
    './tests/specs/mock/settings/*.spec.ts'
  ],
  inbox: [
    './tests/specs/mock/inbox/*.spec.ts'
  ],
  compose: [
    './tests/specs/mock/composeEmail/*.spec.ts'
  ],
  login: [
    './tests/specs/mock/login/*.spec.ts'
  ],
  setup: [
    './tests/specs/mock/setup/*.spec.ts'
  ],
  drafts: [
    './tests/specs/mock/composeEmail/CheckDraftsFunctionality.spec.ts'
  ]
};

config.capabilities = [
  {
    platformName: 'iOS',
    hostname: '127.0.0.1',
    'appium:automationName': 'XCUITest',
    'appium:options': {
      deviceName: 'iPhone 14',
      platformVersion: '16.1',
      app: join(process.cwd(), './FlowCrypt.app'),
      processArguments: { 'args': ['--mock-fes-api', '--mock-attester-api', '--mock-gmail-api'] },
    },
  },
];

exports.config = config;
