const { join } = require('path');

exports.config = {

    runner: 'local',
    framework: 'jasmine',
    jasmineNodeOpts: {
        defaultTimeoutInterval: 300000,
        requires: ['ts-node/register', 'tsconfig-paths/register']
    },
    sync: true,
    logLevel: 'silent',
    deprecationWarnings: true,
    bail: 0,
    waitforTimeout: 15000,
    connectionRetryTimeout: 90000,
    connectionRetryCount: 3,
    maxInstancesPerCapability: 1,
    reporters: ['spec',
        ['allure', {
            outputDir: './tmp',
            disableWebdriverStepsReporting: true,
            disableWebdriverScreenshotsReporting: false,
        }]
    ],
    services: [
        ['appium', {
            command : 'appium',
            logPath : join(process.cwd(), './tmp')
        }]
    ],
    port: 4723,
    path: '/wd/hub',
    specFileRetries: 0,
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
