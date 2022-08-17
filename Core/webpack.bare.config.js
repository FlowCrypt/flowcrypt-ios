/* eslint-disable @typescript-eslint/no-var-requires */
const webpack = require('webpack');
const path = require('path');
/* eslint-enable @typescript-eslint/no-var-requires */

/* eslint-disable @typescript-eslint/naming-convention */
module.exports = {
  target: 'web',
  mode: 'none',
  entry: {
    'entrypoint-bare': './build/ts/entrypoint-bare.js',
    'bare-asn1': './node_modules/asn1.js/lib/asn1.js',
    'web-stream-tools': './node_modules/@openpgp/web-stream-tools/lib/streams.js'
  },
  output: {
    path: __dirname + '/build/bundles/raw',
    filename: '[name].js',
    library: {
      type: 'commonjs2',
    },
    publicPath: '',
    globalObject: 'this',
  },
  plugins: [
    new webpack.ProvidePlugin({
      dereq_sanitize_html: 'sanitize-html',
      dereq_encoding_japanese: 'encoding-japanese',
    }),
  ],
  externals: {
    '../../bundles/raw/web-stream-tools': '../../bundles/raw/web-stream-tools',
  },
  resolve: {
    alias: {
      openpgp: path.resolve(__dirname, './node_modules/openpgp/dist/openpgp.mjs')
    },
    fallback: {
      "stream": false,
      "buffer": false,
      "crypto": false
    }
  }
};