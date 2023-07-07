import { join } from 'path';
import type { Options } from '@wdio/types';
// const video = require('wdio-video-reporter');

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
  logLevel: 'error',
  bail: 0,
  waitforTimeout: 15000,
  connectionRetryTimeout: 400000,
  connectionRetryCount: 3,
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
    // [video, {
    //   saveAllVideos: false,       // If true, also saves videos for successful test cases
    //   outputDir: './tmp/video',
    // }]
  ],
  capabilities: [],
  services: [
    [
      'appium',
      {
        command: './node_modules/.bin/appium',
        logPath: join(process.cwd(), './tmp'),
      },
    ],
  ],
  port: 4723,
  specFileRetries: 1,
  specFileRetriesDeferred: false,

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
