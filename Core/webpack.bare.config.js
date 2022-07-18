module.exports = {
  target: 'web',
  mode: 'none',
  entry: {
    'entrypoint-bare': './build/ts/entrypoint-bare.js',
    'bare-asn1': './node_modules/asn1.js/lib/asn1.js',
    'bare-encoding-japanese': './node_modules/encoding-japanese/encoding.js',
    'sanitize-html': './node_modules/sanitize-html/index.js',
    'web-stream-tools': './node_modules/@openpgp/web-stream-tools/lib/streams.js'
  },
  output: {
    path: __dirname + '/build/bundles/raw',
    filename: '[name].js',
    libraryTarget: 'commonjs2',
    publicPath: '',
    globalObject: 'this',
  },
  externals: {
    openpgp: 'openpgp',
    '../../bundles/raw/web-stream-tools': '../../bundles/raw/web-stream-tools'
  },
  resolve: {
    fallback: {
      "stream": false,
      "buffer": false,
      "crypto": false
    }
  }
};
