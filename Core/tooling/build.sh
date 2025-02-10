#!/usr/bin/env bash

set -euxo pipefail

# clean up
rm -rf ./build/ts ./build/bundles ./build/final/*
mkdir -p ./build/final

# build our source with typescript
./node_modules/.bin/tsc --project tsconfig.json

mkdir -p ./build/ts/lib/streams
cp node_modules/@openpgp/web-stream-tools/lib/*.js ./build/ts/lib/streams

# build raw/ with webpack
./node_modules/.bin/webpack --config webpack.bare.config.js

# move modified raw/ to bundles/
node ./tooling/fix-bundles.js

# concatenate external deps into one bundle
( cd ./build/bundles && cat bare-emailjs-bundle.js bare-zxcvbn-bundle.js > bare-deps-bundle.js )  # bare deps

# create final builds for ios
node ./tooling/build-final.js