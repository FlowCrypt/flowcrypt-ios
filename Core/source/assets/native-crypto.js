/*
 *  cryptographic functions relayed to host app for performance
 */

if (typeof coreHost === 'undefined') {
  // on iOS/JavaScriptCore, coreHost code is injected during startup
  // on Android/NodeJS-mobile, this is defined below manually
  global.coreHost = {
    // methods return promises on Android/Node
    // but return values directly (synchronously) on iOS/JavaScriptCore
    // the code that uses these methods should await the results either way
    decryptRsaNoPadding: (derRsaPrvBase64, encryptedBase64) => hostAsyncRequest('decryptRsaNoPadding', `${derRsaPrvBase64},${encryptedBase64}`),
    verifyRsaModPow: (base, exponent, modulo) => hostAsyncRequest('verifyRsaModPow', `${base},${exponent},${modulo}`),
  };
}

const get_DER_RSAPrivateKey_definition = (ASN1) => {
  return ASN1.define('RSAPrivateKey', function () {
    this.seq().obj(
      this.key('version').int(),
      this.key('modulus').int(),
      this.key('publicExponent').int(),
      this.key('privateExponent').int(),
      this.key('prime1').int(),
      this.key('prime2').int(),
      this.key('exponent1').int(),
      this.key('exponent2').int(),
      this.key('coefficient').int(),
    );
  });
};

const hostRsaDecryption = async (ASN1, BN, c_encrypted, n, e, d, p, q) => {
  const dp = d.mod(p.subn(1)); // d mod (p-1)
  const dq = d.mod(q.subn(1)); // d mod (q-1)
  const u = q.invm(p); // (inverse of q) mod p (as per DER spec. PGP spec has it in the opposite way - that's why we compute our own).
  var derRsaPrvBase64 = get_DER_RSAPrivateKey_definition(ASN1).encode({
    version: 0,
    modulus: n,
    publicExponent: e,
    privateExponent: d,
    prime1: p,
    prime2: q,
    exponent1: dp, //         INTEGER,  -- d mod (p-1)
    exponent2: dq, //        INTEGER,  -- d mod (q-1)
    coefficient: u, //       INTEGER,  -- (inverse of q) mod p
  }, 'der').toString("base64");
  let encryptedBase64 = btoa(openpgp.util.Uint8Array_to_str(c_encrypted.toUint8Array()));
  let decryptedBase64 = await coreHost.decryptRsaNoPadding(derRsaPrvBase64, encryptedBase64);
  if (!decryptedBase64) { // possibly msg-key mismatch
    throw new Error("Session key decryption failed (host)");
  }
  return new BN.default(openpgp.util.b64_to_Uint8Array(decryptedBase64)).toArrayLike(Uint8Array, 'be', n.byteLength());
};
