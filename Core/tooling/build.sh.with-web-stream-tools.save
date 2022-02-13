#!/usr/bin/env bash

set -euxo pipefail

# will remove this when openpgp.js will release all our fixes
echo "Patching openpgp.js v5..."
cp -fv ./source/core/types/openpgp.d.ts ./node_modules/openpgp/
echo "Patching openpgp.js v5 - DONE."

# will remove this when @openpgp/web-stream-tools would release their type definitions
echo "Patching @openpgp/web-stream-tools ..."
cp -fv ./source/core/types/web-stream-tools.d.ts ./node_modules/@openpgp/web-stream-tools/
wst_pkg=./node_modules/@openpgp/web-stream-tools/package.json
set +e
wst_patched=$(grep -n '"types":' $wst_pkg | wc -l)
set -e
if [ $wst_patched = 0 ]; then
    wst_pkg_tmp=${wst_pkg}.tmp
    n=$(grep -n '"main":' $wst_pkg | cut -f1 -d':')
    head -$n ${wst_pkg} >${wst_pkg_tmp}
    echo '  "types": "web-stream-tools.d.ts",' >>${wst_pkg_tmp}
    tail -n $((n+1)) ${wst_pkg} >>${wst_pkg_tmp}
    mv -f ${wst_pkg_tmp} ${wst_pkg}
fi
echo "Patching @openpgp/web-stream-tools - DONE."

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
