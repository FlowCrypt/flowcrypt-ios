# iOS UI tests with Appium

The following commands should be run in `appium` folder.

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. `npm i`

## Run tests

1. `bundle exec fastlane build_e2e`
2. `npm run ios.smoke` (all tests with tag #smoke will be included)

(todo - how to run all tests, how to run one test)
