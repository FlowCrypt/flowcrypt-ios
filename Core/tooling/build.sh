#!/usr/bin/env bash

set -euxo pipefail

# fix openpgp in node_modules
cp -f source/core/types/openpgp.d.ts node_modules/openpgp
for f in openpgp.min.js openpgp.min.js.map openpgp.min.mjs openpgp.min.mjs.map openpgp.mjs; do
  if [ -f node_modules/openpgp/dist/$f ]; then rm -f node_modules/openpgp/dist/$f ; fi
  if [ -f node_modules/openpgp/dist/node/$f ]; then rm -f node_modules/openpgp/dist/node/$f ; fi
done
sed -i 's/openpgp.min.js/openpgp.js/g' node_modules/openpgp/package.json
sed -i 's/openpgp.min.mjs/openpgp.mjs/g' node_modules/openpgp/package.json

extra_exports="
// -----BEGIN ADDED BY FLOWCRYPT----
exports.Hash = Hash;
exports.Sha1 = Sha1;
exports.Sha256 = Sha256;
exports.readToEnd = readToEnd;
exports.util = util;
// -----END ADDED BY FLOWCRYPT-----
"

dist_js=node_modules/openpgp/dist/openpgp.js
tmp_js=${dist_js}.tmp
set +e
fc_added=$(grep 'BEGIN ADDED BY FLOWCRYPT' ${dist_js} | wc -l)
set -e
if [ $fc_added = 0 ]; then
  n=$(grep -n 'exports.verify' ${dist_js} | cut -f1 -d':')
  head -$n ${dist_js} >${tmp_js}
  echo "$extra_exports" >>${tmp_js}
  tail -n +$((n+1)) ${dist_js} >>${tmp_js}
  mv -f ${tmp_js} ${dist_js}
fi

dist_js=node_modules/openpgp/dist/node/openpgp.js
tmp_js=${dist_js}.tmp
set +e
fc_added=$(grep 'BEGIN ADDED BY FLOWCRYPT' ${dist_js} | wc -l)
set -e
if [ $fc_added = 0 ]; then
  cp -f ${dist_js} ${tmp_js}
  echo "$extra_exports" >>${tmp_js}
  mv -f ${tmp_js} ${dist_js}
fi

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
