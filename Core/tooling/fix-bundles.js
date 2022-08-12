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

// update openpgp code to use some native functionality
let entrypointBareSrc = fs.readFileSync(`${bundleRawDir}/entrypoint-bare.js`).toString();

// entrypointBareSrc = replace( // rsa decrypt on host
//   // todo: use randomPayload value on iOS side
//   entrypointBareSrc,
//   /publicKey\.rsa\.decrypt\(c, n, e, d, p, q, u, randomPayload\)/,
//   `await hostRsaDecryption(global.dereq_asn1, bn, c, n, e, d, p, q)`
// );
/* disabled because it works faster without this change */
// entrypointBareSrc = replace( // rsa verify on host
//   entrypointBareSrc,
//   /return publicKey\.rsa\.verify\(hashAlgo, data, s, n, e, hashed\)/, `
//   // returns empty str if not supported: js fallback below
//   const computed = await coreHost.modPow(s.toString(10), e.toString(10), n.toString(10));
//   return computed
//     ? new bn.default(computed, 10).toArrayLike(Uint8Array, 'be', n.byteLength())
//     : await publicKey.rsa.verify(hashAlgo, data, s, n, e, hashed);`
// );
entrypointBareSrc = replace( // bare - produce s2k (decrypt key) on host (because JS sha256 implementation is too slow)
  entrypointBareSrc,
  /toHash = new Uint8Array\(prefixlen \+ count\);/,
  `const algo = enums.read(enums.hash, this.algorithm); return Uint8Array.from(coreHost.produceHashedIteratedS2k(algo, new Uint8Array(), this.salt, passphrase, count));`
);
entrypointBareSrc = replace( // bare - aes decrypt on host
  entrypointBareSrc,
  /return AES_CFB\.decrypt\(ct, key, iv\);/,
  `return Uint8Array.from(coreHost.decryptAesCfbNoPadding(ct, key, iv));`
);

let asn1BareSrc = fs.readFileSync(`${bundleRawDir}/bare-asn1.js`).toString();
asn1BareSrc = replace(
  asn1BareSrc,
  /const asn1 =/gi, 'global.dereq_asn1 ='
);
asn1BareSrc = replace(
  asn1BareSrc,
  /asn1\./gi, 'global.dereq_asn1.'
);

fs.writeFileSync(`${bundleDir}/entrypoint-bare-bundle.js`, `
  ${asn1BareSrc};
  ${entrypointBareSrc};
`);