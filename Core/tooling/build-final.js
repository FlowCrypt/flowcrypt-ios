const fs = require('fs');

const path = {
  beginIos: 'source/assets/flowcrypt-ios-begin.js',
  nativeCrypto: 'source/assets/native-crypto.js',
  bareDepsBundle: 'build/bundles/bare-deps-bundle.js',
  bareEntrypointBundle: 'build/bundles/entrypoint-bare-bundle.js',
  finalDev: 'build/final/flowcrypt-android-dev.js',
  finalIos: 'build/final/flowcrypt-ios-prod.js',
};

// node
const fixNodeImports = (src) => src
  .replace(/require\(['"]bn\.js['"]\)/g, 'dereq_bn')
  .replace(/require\(['"]minimalistic-assert['"]\)/g, 'dereq_minimalistic_assert')
  .replace(/require\(['"]inherits['"]\)/g, 'dereq_inherits')
  .replace(/require\(['"]asn1\.js['"]\)/g, 'dereq_asn1')
  .replace(/require\(['"]encoding-japanese\.js['"]\)/g, 'dereq_encoding_japanese');

// bare
const bareDepsSrc = fs.readFileSync(path.bareDepsBundle).toString();
const bareEntrypointSrc = fs
  .readFileSync(path.bareEntrypointBundle).toString()
  .replace("'[BUILD_REPLACEABLE_VERSION]'", 'APP_VERSION');

// final (node, bare, dev)

const finalBareSrc = `
let global = {};
let _log = (x) => coreHost.log(String(x));
const console = { log: _log, error: _log, info: _log, warn: _log };
try {
  ${fs.readFileSync(path.beginIos).toString()}
  ${fs.readFileSync(path.nativeCrypto).toString()}
  ${bareDepsSrc}
  /* entrypoint-bare starts here */
  ${bareEntrypointSrc}
  /* entrypoint-bare ends here */
  } catch(e) {
    console.error(e instanceof Error ? \`\${e.message}\\n\${(e.stack || 'no stack')
      .split("\\n")
      .map(l => " -> js " + l).join("\\n")}\` : e);
    throw e;
  }
`;

fs.writeFileSync(path.finalIos, finalBareSrc);
