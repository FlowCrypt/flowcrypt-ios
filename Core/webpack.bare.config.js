/* eslint-disable @typescript-eslint/naming-convention */
module.exports = {
  target: 'web',
  mode: 'none',
  entry: {
    'entrypoint-bare': './build/ts/entrypoint-bare.js',
    'bare-encoding-japanese': './node_modules/encoding-japanese/encoding.js',
    'sanitize-html': './node_modules/sanitize-html/index.js',
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
  resolve: {
    fallback: {
      "stream": false,
      // "buffer": false,
      "crypto": false
    }
  }
};
