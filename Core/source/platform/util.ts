/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buffer } from 'buffer';
import { Buf } from '../core/buf';
import { randomBytes } from 'crypto';
import { ConvertStringOptions } from 'encoding-japanese';
import { Key, KeyID, Subkey, UserID } from 'openpgp';

// eslint-disable-next-line @typescript-eslint/naming-convention
declare const dereq_encoding_japanese: {
  convert: (data: Uint8Array, options: ConvertStringOptions) => string;
};

export const secureRandomBytes = (length: number): Uint8Array => {
  return randomBytes(length);
};

export const base64encode = (binary: string): string => {
  return Buffer.from(binary, 'binary').toString('base64');
};

export const base64decode = (b64tr: string): string => {
  return Buffer.from(b64tr, 'base64').toString('binary');
};

export const setGlobals = () => {
  (global as any).btoa = base64encode;
  (global as any).atob = base64decode;
};

export const iso2022jpToUtf = (content: Buf) => {
  return dereq_encoding_japanese.convert(content, { to: 'UTF8', from: 'JIS', type: 'string' });
};

/**
 * Create hex string from a binary.
 * @param {String} str A string to convert.
 * @returns {String} String containing the hexadecimal values.
 * @note This method, brought from OpenPGP.js project is, unlike the rest of the codebase,
 *       licensed under LGPL. See original license file: https://github.com/openpgpjs/openpgpjs/blob/main/LICENSE
 */
export const strToHex = (str: string): string => {
  if (str === null) {
    return "";
  }
  const r = [];
  const e = str.length;
  let c = 0;
  let h;
  while (c < e) {
    h = str.charCodeAt(c++).toString(16);
    while (h.length < 2) {
      h = "0" + h;
    }
    r.push("" + h);
  }
  return r.join('');
};

const maxDate = (dates: (Date | null)[]): Date | null => {
  let res: Date | null = null;
  for (const date of dates) {
    if (res === null || (date !== null && date > res)) {
      res = date;
    }
  }
  return res;
};

const getSubkeyExpirationTime = (subkey: Subkey): number | Date => {
  const bindingCreated = maxDate(subkey.bindingSignatures.map(b => b.created));
  const binding = subkey.bindingSignatures.filter(b => b.created === bindingCreated)[0];
  return binding.getExpirationTime();
};

// Attempt to backport from openpgp.js v4
export const getKeyExpirationTimeForCapabilities = async (
  key: Key,
  capabilities?: 'encrypt' | 'encrypt_sign' | 'sign' | null,
  keyId?: KeyID | undefined,
  userId?: UserID | undefined
): Promise<Date | null | typeof Infinity> => {
  const primaryUser = await key.getPrimaryUser(undefined, userId, undefined);
  if (!primaryUser) throw new Error('Could not find primary user');
  const keyExpiry = await key.getExpirationTime(userId);
  if (!keyExpiry) return null;
  const selfCertCreated = maxDate(primaryUser.user.selfCertifications.map(selfCert => selfCert.created));
  const selfCert = primaryUser.user.selfCertifications.filter(selfCert => selfCert.created === selfCertCreated)[0];
  const sigExpiry = selfCert.getExpirationTime();
  let expiry = keyExpiry < sigExpiry ? keyExpiry : sigExpiry;
  if (capabilities === 'encrypt' || capabilities === 'encrypt_sign') {
    const encryptionKey =
      (await key.getEncryptionKey(keyId, new Date(expiry), userId).catch(() => { return undefined; }))
      || (await key.getEncryptionKey(keyId, null, userId).catch(() => { return undefined; }));
    if (!encryptionKey) return null;
    // for some reason, "instanceof Key" didn't work: 'Right-hand side of \'instanceof\' is not an object'
    const encryptionKeyExpiry = 'bindingSignatures' in encryptionKey
      ? getSubkeyExpirationTime(encryptionKey)
      : (await encryptionKey.getExpirationTime(userId))!;
    if (encryptionKeyExpiry < expiry) expiry = encryptionKeyExpiry;
  }
  if (capabilities === 'sign' || capabilities === 'encrypt_sign') {
    const signatureKey =
      (await key.getSigningKey(keyId, new Date(expiry), userId).catch(() => { return undefined; }))
      || (await key.getSigningKey(keyId, null, userId).catch(() => { return undefined; }));
    if (!signatureKey) return null;
    // could be the same as above, so checking for property instead of using "instanceof"
    const signatureKeyExpiry = 'bindingSignatures' in signatureKey
      ? await getSubkeyExpirationTime(signatureKey)
      : (await signatureKey.getExpirationTime(userId))!;
    if (signatureKeyExpiry < expiry) expiry = signatureKeyExpiry;
  }
  return expiry;
};
