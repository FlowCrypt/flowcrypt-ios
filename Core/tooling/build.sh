#!/usr/bin/env bash

set -euxo pipefail

# fix openpgp in node_modules
echo "Patching openpgp.js v5..."
# will remove this when openpgp.js will release all our fixes
cp -fv ./source/core/types/openpgp.d.ts ./node_modules/openpgp/
echo "Patching openpgp.js v5 - DONE."

# clean up
rm -rf ./build/ts ./build/bundles ./build/final/*
mkdir -p ./build/final

# build our source with typescript
./node_modules/.bin/tsc --project tsconfig.json

# build raw/ with webpack
./node_modules/.bin/webpack --config webpack.bare.config.js

# move modified raw/ to bundles/
node ./tooling/fix-bundles.js

# concatenate external deps into one bundle
( cd ./build/bundles && cat bare-html-sanitize-bundle.js bare-emailjs-bundle.js bare-openpgp-bundle.js bare-zxcvbn-bundle.js bare-encoding-japanese.js > bare-deps-bundle.js )  # bare deps

# create final builds for dev, ios, android
node ./tooling/build-final.js
