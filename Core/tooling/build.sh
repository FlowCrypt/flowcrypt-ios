#!/usr/bin/env bash

set -euxo pipefail

# clean up
rm -rf build/ts build/bundles build/final/*
mkdir -p build/final

# build our source with typescript
./node_modules/.bin/tsc --project tsconfig.json

# build raw/ with webpack
./node_modules/.bin/webpack --config webpack.node.config.js
./node_modules/.bin/webpack --config webpack.bare.config.js

# move modified raw/ to bundles/
node tooling/fix-bundles.js

# concatenate external deps into one bundle
( cd build/bundles && cat node-html-sanitize-bundle.js node-emailjs-bundle.js node-openpgp-bundle.js > node-deps-bundle.js )  # node deps
( cd build/bundles && cat node-html-sanitize-bundle.js node-emailjs-bundle.js node-dev-openpgp-bundle.js > node-dev-deps-bundle.js )  # node dev - for tests
( cd build/bundles && cat bare-html-sanitize-bundle.js bare-emailjs-bundle.js bare-openpgp-bundle.js bare-zxcvbn-bundle.js > bare-deps-bundle.js )  # bare deps

# create final builds for dev, ios, android
node tooling/build-final.js
