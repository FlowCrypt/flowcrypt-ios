const { join } = require('path');
const video = require('wdio-video-reporter');

process.on('unhandledRejection', (reason, promise) => {
  // without this, after lib update to v7, whole test suite may pass even if no tests ran successfully
  console.error('Force-quitting node process because unhandled rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

exports.config = {

  runner: 'local',
  framework: 'jasmine',
  jasmineOpts: {
    defaultTimeoutInterval: 600000,
    requires: ['tsconfig-paths/register']
  },
  sync: true,
  logLevel: 'debug',
  deprecationWarnings: true,
  bail: 0,
  waitforTimeout: 15000,
  connectionRetryTimeout: 90000,
  connectionRetryCount: 3,
  maxInstancesPerCapability: 1,
  reporters: [
    'spec',
    ['junit', {
      outputDir: './tmp/test-results',
      outputFileFormat: function (options) {
        return `wdio-${options.cid}.xml`
      }
    }],
    [video, {
      saveAllVideos: true,       // If true, also saves videos for successful test cases
      // videoSlowdownMultiplier: 3, // Higher to get slower videos, lower for faster videos [Value 1-100]
      videoRenderTimeout: 10,      // Max seconds to wait for a video to finish rendering
      //   outputDir: './video',
    }]
  ],
  services: [
    ['appium', {
      command: './node_modules/.bin/appium',
      logPath: join(process.cwd(), './tmp')
    }]
  ],
  port: 4723,
  path: '/wd/hub',
  specFileRetries: 1,
  specFileRetriesDeferred: false,

  afterTest: function (test, context, { error, result, duration, passed, retries }) {
    if (error) {
      const timestampNow = new Date().getTime().toString();
      const path = join(process.cwd(), './tmp');
      driver.saveScreenshot(`${path}/${timestampNow}.png`);
      console.log("Screenshot of failed test was saved to " + path)
    }
  }
};
