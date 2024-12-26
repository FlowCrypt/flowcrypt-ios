import { join } from 'path';
import type { Options } from '@wdio/types';

process.on('unhandledRejection', (reason, promise) => {
  // without this, after lib update to v7, whole test suite may pass even if no tests ran successfully
  console.error('Force-quitting node process because unhandled rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('SIGINT', () => {
  process.exit(1);
});

export const config: Options.Testrunner = {
  autoCompileOpts: {
    tsNodeOpts: {
      project: './tsconfig.json',
    },
  },
  runner: 'local',
  framework: 'jasmine',
  jasmineOpts: {
    defaultTimeoutInterval: 600000,
  },
  logLevel: 'debug',
  bail: 1,
  waitforTimeout: 15000,
  connectionRetryTimeout: 400000,
  connectionRetryCount: 2,
  maxInstancesPerCapability: 1,
  reporters: [
    'spec',
    [
      'junit',
      {
        outputDir: './tmp/test-results',
        outputFileFormat: function (options) {
          return `wdio-${options.cid}.xml`;
        },
      },
    ],
  ],
  capabilities: [],
  services: [
    [
      'appium',
      {
        args: {
          relaxedSecurity: true,
        },
        command: './node_modules/.bin/appium',
        logPath: join(process.cwd(), './tmp'),
      },
    ],
  ],
  port: 4723,
  specFileRetries: 1,
  specFileRetriesDelay: 10,

  afterTest: async function (_test, _context, { passed }) {
    if (!passed) {
      try {
        const timestampNow = new Date().getTime().toString();
        const path = join(process.cwd(), './tmp');
        await browser.saveScreenshot(`${path}/${timestampNow}.png`);
        console.log('Screenshot of failed test was saved to ' + path);
      } catch (e) {
        console.error(`Error occurred while saving screenshot. Error: ${e}`);
      }
    }
  },
};
