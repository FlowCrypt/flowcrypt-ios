
const nodeExternals = require('webpack-node-externals');

module.exports = {
  target: 'node',
  externals: [nodeExternals()],
  mode: 'none',
  entry: {
    'entrypoint-node': './build/ts/entrypoint-node.js',
    'node-asn1': './node_modules/asn1.js/lib/asn1.js',
    'bn': './node_modules/bn.js/lib/bn.js',
    'minimalistic-assert': './node_modules/minimalistic-assert/index.js',
    'node-html-sanitize': './node_modules/sanitize-html/dist/sanitize-html.js',
    // 'emailjs-mime-parser': './node_modules/emailjs-mime-parser/dist/mimeparser.js' // this works with latest version from Node - can use later
  },
  output: {
    path: __dirname + '/build/bundles/raw',
    filename: '[name].js',
    libraryTarget: 'commonjs2'
  },
  module: {
    rules: [{
      test: /\.js$/,
      use: {
        loader: 'babel-loader',
        options: {
          presets: [
            ['env', { 'targets': { 'node': '8.6.0' } }]
          ]
        }
      }
    }]
  }
}
