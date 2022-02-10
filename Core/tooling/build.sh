#!/usr/bin/env bash

set -euxo pipefail

# fix openpgp in node_modules
echo "Patching openpgp.js v5..."
for f in openpgp.min.js openpgp.min.js.map openpgp.min.mjs openpgp.min.mjs.map openpgp.mjs; do
  if [ -f node_modules/openpgp/dist/$f ]; then rm -f node_modules/openpgp/dist/$f ; fi
  if [ -f node_modules/openpgp/dist/node/$f ]; then rm -f node_modules/openpgp/dist/node/$f ; fi
done
cp -Rfv source/lib/openpgpjs-v5/* node_modules/openpgp/
# MacOS sed is old BSD sed w/o "-i" (see https://ss64.com/osx/sed.html)
sed 's/openpgp.min.js/openpgp.js/g' node_modules/openpgp/package.json >node_modules/openpgp/package.json.tmp
cp -f node_modules/openpgp/package.json.tmp node_modules/openpgp/package.json
sed 's/openpgp.min.mjs/openpgp.mjs/g' node_modules/openpgp/package.json >node_modules/openpgp/package.json.tmp
cp -f node_modules/openpgp/package.json.tmp node_modules/openpgp/package.json
echo "Patching openpgp.js v5 - DONE."

# clean up
rm -rf build/ts build/bundles build/final/*
mkdir -p build/final

# build our source with typescript
node_modules/.bin/tsc --project tsconfig.json

# build raw/ with webpack
node_modules/.bin/webpack --config webpack.bare.config.js

# move modified raw/ to bundles/
node tooling/fix-bundles.js

# concatenate external deps into one bundle
( cd build/bundles && cat bare-html-sanitize-bundle.js bare-emailjs-bundle.js bare-openpgp-bundle.js bare-zxcvbn-bundle.js bare-encoding-japanese.js > bare-deps-bundle.js )  # bare deps

# create final builds for dev, ios, android
node tooling/build-final.js
