
const fs = require('fs');

const path = {
  beginAndroidDev: 'source/assets/flowcrypt-android-dev-begin.js',
  beginIos: 'source/assets/flowcrypt-ios-begin.js',
  nativeCrypto: 'source/assets/native-crypto.js',
  nodeDepsBundle: 'build/bundles/node-deps-bundle.js',
  nodeDevDepsBundle: 'build/bundles/node-dev-deps-bundle.js',
  bareDepsBundle: 'build/bundles/bare-deps-bundle.js',
  bareEntrypointBundle: 'build/bundles/entrypoint-bare-bundle.js',
  nodeEntrypointBundle: 'build/bundles/entrypoint-node-bundle.js',
  finalDev: 'build/final/flowcrypt-android-dev.js',
  finalIos: 'build/final/flowcrypt-ios-prod.js',
  finalAndroid: 'build/final/flowcrypt-android-prod.js',
}

// node
const fixNodeImports = (src) => src
  .replace(/require\(['"]bn\.js['"]\)/g, 'dereq_bn')
  .replace(/require\(['"]minimalistic-assert['"]\)/g, 'dereq_minimalistic_assert')
  .replace(/require\(['"]inherits['"]\)/g, 'dereq_inherits')
  .replace(/require\(['"]asn1\.js['"]\)/g, 'dereq_asn1');
const nodeDepsSrc = fixNodeImports(fs.readFileSync(path.nodeDepsBundle).toString())
const nodeDevDepsSrc = fixNodeImports(fs.readFileSync(path.nodeDevDepsBundle).toString())
const nodeEntrypointSrc = fs.readFileSync(path.nodeEntrypointBundle).toString().replace("'[BUILD_REPLACEABLE_VERSION]'", 'APP_VERSION');

// bare
const bareDepsSrc = fs.readFileSync(path.bareDepsBundle).toString()
const bareEntrypointSrc = fs.readFileSync(path.bareEntrypointBundle).toString().replace("'[BUILD_REPLACEABLE_VERSION]'", 'APP_VERSION');

// final (node, bare, dev)

const finalNodeSrc = `
try {
  /* final flowcrypt-android bundle starts here */
  const dereq_inherits = require("util").inherits; // standard node util, not to interfere with webpack require, which cannot resolve it
  ${fs.readFileSync(path.nativeCrypto).toString()}
  ${nodeDepsSrc}
  ${nodeEntrypointSrc}
  /* final flowcrypt-android bundle ends here */
} catch(e) {
  console.error(e);
}
`;

const finalNodeDevSrc = `
try {
  /* final flowcrypt-android bundle starts here */
  const dereq_inherits = require("util").inherits; // standard node util, not to interfere with webpack require, which cannot resolve it
  ${fs.readFileSync(path.beginAndroidDev).toString()}
  ${fs.readFileSync(path.nativeCrypto).toString()}
  ${nodeDevDepsSrc}
  ${nodeEntrypointSrc}
  /* final flowcrypt-android bundle ends here */
} catch(e) {
  console.error(e);
}
`;

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
    console.error(e instanceof Error ? \`\${e.message}\\n\${(e.stack || 'no stack').split("\\n").map(l => " -> js " + l).join("\\n")}\` : e);
    throw e;
  }
`;

fs.writeFileSync(path.finalDev, finalNodeDevSrc);
fs.writeFileSync(path.finalIos, finalBareSrc);
fs.writeFileSync(path.finalAndroid, finalNodeSrc);
