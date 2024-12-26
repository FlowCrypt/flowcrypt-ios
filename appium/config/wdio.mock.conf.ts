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
    'wdio:maxInstances': 1,
    hostname: '127.0.0.1',
    'appium:automationName': 'XCUITest',
    'appium:processArguments': {
      args: ['--mock-fes-api', '--mock-attester-api', '--mock-gmail-api'],
    },
    'appium:deviceName': 'iPhone SE (3rd generation)',
    'appium:platformVersion': '18.2',
    'appium:orientation': 'PORTRAIT',
    'appium:noReset': true,
    'appium:app': join(process.cwd(), './FlowCrypt.app'),
    'appium:simulatorStartupTimeout': 300000,
    'appium:newCommandTimeout': 240,
    'appium:webviewConnectTimeout': 5000,
    'appium:reduceMotion': true,
    'appium:simulatorLogLevel': 'debug',
    'appium:prebuiltWDAPath': join(process.cwd(), './WebDriverAgentRunner-Runner.app'),
    'appium:usePreinstalledWDA': true,
  },
];

exports.config = config;
