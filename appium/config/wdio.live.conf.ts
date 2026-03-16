import { join } from 'path';
import { config } from './wdio.shared.conf';

config.suites = {
  all: ['../tests/specs/live/**/*.spec.ts'],
};

config.capabilities = [
  {
    platformName: 'iOS',
    hostname: '127.0.0.1',
    'appium:automationName': 'XCUITest',
    'appium:deviceName': 'iPhone 17',
    'appium:platformVersion': '26.1',
    'appium:app': join(process.cwd(), './FlowCrypt.app'),
  },
];

exports.config = config;
