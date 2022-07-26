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
fs.copyFileSync(`${bundleRawDir}/entrypoint-bare.js`, `${bundleDir}/entrypoint-bare-bundle.js`);

const sanitizeHtmlDist = `${bundleWipDir}/sanitize-html.js`;

// copy wip to html-sanitize-bundle
fs.writeFileSync(
  `${bundleDir}/bare-html-sanitize-bundle.js`,
  fs.readFileSync(sanitizeHtmlDist).toString()
);

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

fs.copyFileSync(`${bundleWipDir}/bare-encoding-japanese.js`, `${bundleDir}/bare-encoding-japanese.js`);
