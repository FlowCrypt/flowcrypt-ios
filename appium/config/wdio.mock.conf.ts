import { join } from 'path';
import { config } from './wdio.shared.conf';

config.suites = {
  all: ['../tests/specs/mock/**/*.spec.ts'],
  settings: ['../tests/specs/mock/settings/*.spec.ts'],
  inbox: ['../tests/specs/mock/inbox/*.spec.ts'],
  compose: ['../tests/specs/mock/composeEmail/*.spec.ts'],
  login: ['../tests/specs/mock/login/*.spec.ts'],
  setup: ['../tests/specs/mock/setup/*.spec.ts'],
  drafts: ['../tests/specs/mock/composeEmail/CheckDraftsFunctionality.spec.ts'],
};

config.capabilities = [
  {
    platformName: 'iOS',
    maxInstances: 1,
    hostname: '127.0.0.1',
    'appium:automationName': 'XCUITest',
    'appium:processArguments': {
      args: ['--mock-fes-api', '--mock-attester-api', '--mock-gmail-api'],
    },
    'appium:deviceName': 'iPhone 15',
    'appium:platformVersion': '17.5',
    'appium:orientation': 'PORTRAIT',
    'appium:app': join(process.cwd(), './FlowCrypt.app'),
    'appium:newCommandTimeout': 240,
    'appium:webviewConnectTimeout': 5000,
  },
];

exports.config = config;
