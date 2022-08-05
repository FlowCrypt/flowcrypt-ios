// eslint-disable-next-line @typescript-eslint/no-var-requires
const webpack = require('webpack');

/* eslint-disable @typescript-eslint/naming-convention */
module.exports = {
  target: 'web',
  mode: 'none',
  entry: {
    'entrypoint-bare': './build/ts/entrypoint-bare.js',
    'bare-asn1': './node_modules/asn1.js/lib/asn1.js',
    'bare-encoding-japanese': './node_modules/encoding-japanese/encoding.js',
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
      // openpgp: 'openpgp',
      // readToEnd: ['@openpgp/web-stream-tools', 'readToEnd']
    }),
  ],
  externals: {
    // '@openpgp/web-stream-tools': 'web-stream-tools',
    // openpgp: 'openpgp',
    '../../bundles/raw/web-stream-tools': '../../bundles/raw/web-stream-tools',
  },
  resolve: {
    fallback: {
      "stream": false,
      "buffer": false,
      "crypto": false,
    }
  }
};
