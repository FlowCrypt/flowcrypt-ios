

const fs = require('fs');

const libsDir = 'source/lib';
const bundleDir = 'build/bundles'
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
    let fixedExportSrc = src.replace(/^module\.exports =\n/, `const ${importableName} =\n`);
    fs.writeFileSync(`${bundleWipDir}/${filename}`, fixedExportSrc);
  }
}

// copy raw to flowcrypt-bundle
fs.copyFileSync(`${bundleRawDir}/entrypoint-node.js`, `${bundleDir}/entrypoint-node-bundle.js`);
fs.copyFileSync(`${bundleRawDir}/entrypoint-bare.js`, `${bundleDir}/entrypoint-bare-bundle.js`);

const sanitizeHtmlDist = './node_modules/sanitize-html/dist/sanitize-html.js';

// * -- REMOVE THIS AND UPDATE sanitize-html WHEN PR LANDS: https://github.com/apostrophecms/sanitize-html/pull/326
// this patches the source directly in node_modules, because we also use it directly during tests
fs.writeFileSync(sanitizeHtmlDist, fs.readFileSync(sanitizeHtmlDist).toString().replace(/if\(value\.length\)/g, 'if(value&&value.length)'));
// -- *

// copy wip to html-sanitize-bundle
fs.copyFileSync(`${bundleWipDir}/node-html-sanitize.js`, `${bundleDir}/node-html-sanitize-bundle.js`);
fs.writeFileSync(
  `${bundleDir}/bare-html-sanitize-bundle.js`,
  `${fs.readFileSync(sanitizeHtmlDist).toString()}\nconst dereq_html_sanitize = window.sanitizeHtml;\n`
);

// copy zxcvbn, only used for bare (iOS) because zxcvbn-ios is not well maintained: https://github.com/dropbox/zxcvbn-ios/issues
// todo - could add `\nconst zxcvbn = window.zxcvbn;` at the end, then could call it directly from endpoint.ts
fs.copyFileSync('./node_modules/zxcvbn/dist/zxcvbn.js', `${bundleDir}/bare-zxcvbn-bundle.js`);

// // concat emailjs bundle/wip to become emailjs-bundle 
// fs.writeFileSync(`${bundleDir}/emailjs-bundle.js`, [ // this would work when using modules directly from Node - we don't do that yet
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
  .replace(/require\(['"](punycode|emailjs-[a-z\-]+)['"]\)/g, found => found.replace('require(', 'global[').replace(')', ']'))
  .replace(/typeof define === 'function' && define\.amd/g, 'false')
  .replace(/typeof exports ===? 'object'/g, 'false');
fs.writeFileSync(`${bundleDir}/bare-emailjs-bundle.js`, `\n(function(){\n// begin emailjs\n${emailjsRawDep}\n// end emailjs\n})();\n`);
fs.writeFileSync(`${bundleDir}/node-emailjs-bundle.js`, `\n(function(){\n// begin emailjs\n${emailjsNodeDep}\n// end emailjs\n})();\n`);

const replace = (libSrc, regex, replacement) => {
  if (!regex.test(libSrc)) {
    throw new Error(`Could not find ${regex} in openpgp.js`)
  }
  return libSrc.replace(regex, replacement);
}

let openpgpLib = fs.readFileSync('source/lib/openpgp.js').toString();
const openpgpLibNodeDev = openpgpLib; // dev node runs without any host, no modifications needed

openpgpLib = replace( // rsa decrypt on host
  openpgpLib,
  /[a-z0-9A-Z_]+\.default\.rsa\.decrypt\(c, n, e, d, p, q, u\)/,
  `await hostRsaDecryption(dereq_asn1, _bn2, data_params[0], n, e, d, p, q)`
);

openpgpLib = replace( // rsa verify on host
  openpgpLib,
  /const EM = await _public_key2\.default\.rsa\.verify\(m, n, e\);/, `
  const computed = await coreHost.verifyRsaModPow(m.toString(10), e.toString(10), n.toString(10)); // returns empty str if not supported: js fallback below
  const EM = computed ? new _bn2.default(computed, 10).toArrayLike(Uint8Array, 'be', n.byteLength()) : await _public_key2.default.rsa.verify(m, n, e);`
);

let openpgpLibNode = openpgpLib; // no more modifications for node code
let openpgpLibBare = openpgpLib; // further modify bare code below

openpgpLibBare = replace( // bare - produce s2k (decrypt key) on host (because JS sha256 implementation is too slow)
  openpgpLibBare,
  /const data = _util2\.default\.concatUint8Array\(\[s2k\.salt, passphrase\]\);/,
  `return Uint8Array.from(coreHost.produceHashedIteratedS2k(s2k.algorithm, prefix, s2k.salt, passphrase, count));`
);

openpgpLibBare = replace( // bare - aes decrypt on host
  openpgpLibBare,
  /return _cfb\.AES_CFB\.decrypt\(ct, key, iv\);/,
  `return Uint8Array.from(coreHost.decryptAesCfbNoPadding(ct, key, iv));`
);

const asn1LibBare = fs.readFileSync(`${bundleWipDir}/bare-asn1.js`).toString();

const asn1libNode = fs.readFileSync(`${bundleWipDir}/node-asn1.js`).toString()
  .replace(/require\("safer-buffer"\)/g, 'require("buffer")'); // we don't use old node versions

const minimalisticAssertLibNode = fs.readFileSync(`${bundleWipDir}/minimalistic-assert.js`).toString();

const bnLibNode = fs.readFileSync(`${bundleWipDir}/bn.js`).toString();

fs.writeFileSync(`${bundleDir}/bare-openpgp-bundle.js`, `
  ${fs.readFileSync('source/lib/web-streams-polyfill.js').toString()}
  const ReadableStream = self.ReadableStream;
  const WritableStream = self.WritableStream;
  const TransformStream = self.TransformStream;
  /* asn1 begin */
  ${asn1LibBare}
  /* asn1 end */
  ${openpgpLibBare}
  const openpgp = window.openpgp;
`);

fs.writeFileSync(`${bundleDir}/node-openpgp-bundle.js`, `
  (function(){
    console.debug = console.log;
    ${minimalisticAssertLibNode}
    ${bnLibNode}
    ${asn1libNode}
    ${openpgpLibNode}
    const openpgp = module.exports;
    module.exports = {};
    global['openpgp'] = openpgp;
  })();
`);

fs.writeFileSync(`${bundleDir}/node-dev-openpgp-bundle.js`, `
  (function(){
    console.debug = console.log;
    ${minimalisticAssertLibNode}
    ${bnLibNode}
    ${asn1libNode}
    ${openpgpLibNodeDev}
    const openpgp = module.exports;
    module.exports = {};
    global['openpgp'] = openpgp;
  })();
`);
