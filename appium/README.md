# iOS UI tests with Appium

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. This git repository must be located in `~/git/flowcrypt-ios/`
3. `cd appium && npm install`

## Run tests

Run this in `appium` folder. 

`npm test` - build `FlowCrypt.app` and run all ui tests

`npm run-script only.test.all` - run all ui tests without building the `.app`. Use this if you already built the `.app` before, and now only want to change the UI test spec without rebuilding the app

To only run a single test, find the test you want to run and change `it(` to `iit(` on that test, then run tests. Don't push this change to git, as it would affect CI too.
