# iOS UI tests with Appium

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. `cd appium && npm i`

## Run tests

1. `bundle exec fastlane build`
2. `cd appium && npm run ios.smoke` (all tests with tag #smoke will be included)

(todo - how to run all tests, how to run one test)
