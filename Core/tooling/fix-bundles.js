const fs = require('fs');

const libsDir = 'source/lib';
const bundleDir = 'build/bundles';
const bundleRawDir = `${bundleDir}/raw`;
const bundleWipDir = `${bundleDir}/wip`;

try {
  fs.mkdirSync(bundleWipDir);
} catch (e) {
  if (String(e).indexOf('file already exists') === -1) {
    throw e;
  }
}

// fix up all bundles/raw to become bundles/wip
for (const filename of fs.readdirSync(bundleRawDir)) {
  if (!filename.startsWith('entrypoint-')) {
    const src = fs.readFileSync(`${bundleRawDir}/${filename}`).toString();
    const importableName = `dereq_${filename.replace(/\.js$/, '').replace(/^(node|bare)-/, '').replace(/-/g, '_')}`;
    const fixedExportSrc = src.replace(/^module\.exports =\n/, `const ${importableName} =\n`);
    fs.writeFileSync(`${bundleWipDir}/${filename}`, fixedExportSrc);
  }
}

// copy raw to flowcrypt-bundle
// module.exports = require("../../bundles/raw/web-stream-tools");
fs.copyFileSync(`${bundleRawDir}/entrypoint-bare.js`, `${bundleDir}/entrypoint-bare-bundle.js`);

// copy zxcvbn, only used for bare (iOS) because zxcvbn-ios is not well maintained:
// https://github.com/dropbox/zxcvbn-ios/issues
// todo - could add `\nconst zxcvbn = window.zxcvbn;` at the end, then could call it directly from endpoint.ts
fs.copyFileSync('./node_modules/zxcvbn/dist/zxcvbn.js', `${bundleDir}/bare-zxcvbn-bundle.js`);

// this would work when using modules directly from Node - we don't do that yet
// // concat emailjs bundle/wip to become emailjs-bundle
// fs.writeFileSync(`${bundleDir}/emailjs-bundle.js`, [
//   `${bundleWipDir}/emailjs-mime-parser.js`,
//   `${bundleWipDir}/emailjs-mime-builder.js`,
// ].map(path => fs.readFileSync(path).toString()).join('\n'));

// concat emailjs libs/* to become emailjs-bundle
const emailjsRawDep = [
  `${libsDir}/iso-8859-2.js`,
  `${libsDir}/emailjs/punycode.js`,
  `${libsDir}/emailjs/emailjs-stringencoding.js`,
  `${libsDir}/emailjs/emailjs-mime-types.js`,
  `${libsDir}/emailjs/emailjs-mime-codec.js`,
  `${libsDir}/emailjs/emailjs-addressparser.js`,
  `${libsDir}/emailjs/emailjs-mime-parser.js`,
  `${libsDir}/emailjs/emailjs-mime-builder.js`,
].map(path => fs.readFileSync(path).toString()).join('\n');
const emailjsNodeDep = emailjsRawDep // these replacements fix imports and exports of modules for use in nodejs-mobile
  .replace(/require\(['"]buffer['"]\)\.Buffer/g, 'Buffer')
  .replace(/require\(['"](punycode|emailjs-[a-z\-]+)['"]\)/g, found =>
    found.replace('require(', 'global[').replace(')', ']')
  )
  .replace(/typeof define === 'function' && define\.amd/g, 'false')
  .replace(/typeof exports ===? 'object'/g, 'false');
fs.writeFileSync(
  `${bundleDir}/bare-emailjs-bundle.js`,
  `\n(function(){\n// begin emailjs\n${emailjsRawDep}\n// end emailjs\n})();\n`
);
fs.writeFileSync(
  `${bundleDir}/node-emailjs-bundle.js`,
  `\n(function(){\n// begin emailjs\n${emailjsNodeDep}\n// end emailjs\n})();\n`
);

const replace = (libSrc, regex, replacement) => {
  if (!regex.test(libSrc)) {
    throw new Error(`Could not find ${regex} in openpgp.js`)
  }
  return libSrc.replace(regex, replacement);
}

let openpgpLib = fs.readFileSync('./node_modules/openpgp/dist/node/openpgp.js').toString();
const openpgpLibNodeDev = openpgpLib; // dev node runs without any host, no modifications needed

openpgpLib = replace( // rsa decrypt on host
  // todo: use randomPayload value on iOS side
  openpgpLib,
  /publicKey\.rsa\.decrypt\(c, n, e, d, p, q, u, randomPayload\)/,
  `await hostRsaDecryption(dereq_asn1, _bn2, data_params[0], n, e, d, p, q)`
);
openpgpLib = replace( // rsa verify on host
  openpgpLib,
  /return publicKey\.rsa\.verify\(hashAlgo, data, s, n, e, hashed\)/, `
  // returns empty str if not supported: js fallback below
  const computed = await coreHost.modPow(s.toString(10), e.toString(10), n.toString(10));
  return computed
    ? new _bn2.default(computed, 10).toArrayLike(Uint8Array, 'be', n.byteLength())
    : await publicKey.rsa.verify(hashAlgo, data, s, n, e, hashed);`
);

let openpgpLibBare = openpgpLib; // further modify bare code below

openpgpLibBare = replace( // bare - produce s2k (decrypt key) on host (because JS sha256 implementation is too slow)
  openpgpLibBare,
  /const data = util\.concatUint8Array\(\[this\.salt, passphrase\]\);/,
  // todo: prefix isn't available in js code
  `return Uint8Array.from(coreHost.produceHashedIteratedS2k(this.algorithm, prefix, this.salt, passphrase, count));`
);
openpgpLibBare = replace( // bare - aes decrypt on host
  openpgpLibBare,
  /return AES_CFB\.decrypt\(ct, key, iv\);/,
  `return Uint8Array.from(coreHost.decryptAesCfbNoPadding(ct, key, iv));`
);

const webStreamLibBare = ''; // fs.readFileSync(`${bundleWipDir}/web-stream-tools.js`).toString();
const asn1LibBare = fs.readFileSync(`${bundleWipDir}/bare-asn1.js`).toString();

fs.writeFileSync(`${bundleDir}/bare-openpgp-bundle.js`, `
  /* asn1 begin */
  ${asn1LibBare}
  /* asn1 end */
  /* web-stream-tool begin */
  ${webStreamLibBare}
  /* web-stream-tools end */
  ${openpgpLibBare}
  const openpgp = window.openpgp;
`);

fs.writeFileSync(`${bundleDir}/node-dev-openpgp-bundle.js`, `
  (function(){
    console.debug = console.log;
    ${openpgpLibNodeDev}
    const openpgp = module.exports;
    module.exports = {};
    global['openpgp'] = openpgp;
  })();
`);

fs.copyFileSync(`${bundleWipDir}/bare-encoding-japanese.js`, `${bundleDir}/bare-encoding-japanese.js`);
