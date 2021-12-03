# iOS UI tests with Appium

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. This git repository must be located in `~/git/flowcrypt-ios/` so that `FlowCrypt.app` gets copied to the right place.
3. `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`
4. `echo -e '\n\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"\n' >> ~/.bash_profile`
5. restart terminal
6. `nvm install 16` - installs NodeJS 16 and sets it as default
7. `cd ~/git/flowcrypt-ios/appium && npm install`

## Building app for testing

Run this in `flowcrypt-ios` folder: `bundle exec fastlane build`. This will produce folder `appium/FlowCrypt.app` that contains the built app.

## Run tests

Run these in `appium` folder.

Tests that use live APIs:
- `npm run-script only.test.live.all` - run all ui tests
- `npm run-script only.test.live.filter "user is able to view text email"` - run a particular ui test 

Tests that use mock APIs:
- `npm run-script only.test.mock.all` - run all ui tests against mocks
- `npm run-script only.test.mock.filter "app setup fails with bad EKM URL"` - run a particular ui test against mocks
