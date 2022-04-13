
/** Create signature
 * @param {BN} m message
 * @param {BN} n RSA public modulus
 * @param {BN} e RSA public exponent
 * @param {BN} d RSA private exponent
 * @returns {BN} RSA Signature
 * @async
 */
const sign = async function sign(m, n, e, d) {
  console.log('begin sign: async function sign(m, n, e, d)');
  console.log(`(message) m ${m.toString(10)}`);
  console.log(`(public modulus) n ${m.toString(10)}`);
  console.log(`(private exponent) d ${m.toString(10)}`);
  if (n.cmp(m) <= 0) {
    throw new Error('Message size cannot exceed modulus size');
  }
  const nred = new _bn2.default.red(n);
  const signResultBeforeArrayLike = m.toRed(nred).redPow(d);
  console.log(`js sign BEFORE array like result: ${signResultBeforeArrayLike.toString(10)}`);
  const signResult = signResultBeforeArrayLike.toArrayLike(Uint8Array, 'be', n.byteLength());
  console.log(`js sign AFTER array like result: ${signResult.toString(10)}`);
  console.log('end sign: async function sign(m, n, e, d)');
  return signResult;
}

