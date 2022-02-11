/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from '../core/buf';
import { randomBytes } from 'crypto';
import { ConvertStringOptions } from 'encoding-japanese';
import { Key, KeyID, Subkey, UserID } from 'openpgp';

declare const dereq_encoding_japanese : {
  convert: (data: Uint8Array, options: ConvertStringOptions) => string;
};

export const secureRandomBytes = (length: number): Uint8Array => {
  return randomBytes(length);
}

export const base64encode = (binary: string): string => {
  return Buffer.from(binary, 'binary').toString('base64');
}

export const base64decode = (b64tr: string): string => {
  return Buffer.from(b64tr, 'base64').toString('binary');
}

export const setGlobals = () => {
  (global as any).btoa = base64encode;
  (global as any).atob = base64decode;
}

export const iso2022jpToUtf = (content: Buf) => {
  return dereq_encoding_japanese.convert(content, { to: 'UTF8', from: 'JIS', type: 'string' });
}

/**
 * Create hex string from a binary
 * @param {String} str String to convert
 * @returns {String} String containing the hexadecimal values
 */
export const str_to_hex = (str: string): string => {
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
}

const maxDate = (dates: (Date | null)[]): Date | null => {
  let res: Date | null = null;
  for (const date of dates) {
    if (res == null || (date != null && date > res)) {
      res = date;
    }
  }
  return res;
}

const getSubkeyExpirationTime = (subkey: Subkey): number | Date => {
  const bindingCreated = maxDate(subkey.bindingSignatures.map(b => b.created));
  const binding = subkey.bindingSignatures.filter(b => b.created === bindingCreated)[0];
  return binding.getExpirationTime();
}

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
  if (!keyExpiry) return Infinity;
  const selfCertCreated = maxDate(primaryUser.user.selfCertifications.map(selfCert => selfCert.created));
  const selfCert = primaryUser.user.selfCertifications.filter(selfCert => selfCert.created === selfCertCreated)[0];
  const sigExpiry = selfCert.getExpirationTime();
  let expiry = keyExpiry < sigExpiry ? keyExpiry : sigExpiry;
  if (capabilities === 'encrypt' || capabilities === 'encrypt_sign') {
    const encryptionKey = (await key.getEncryptionKey(keyId, new Date(expiry), userId))
      || (await key.getEncryptionKey(keyId, null, userId));
    if (!encryptionKey) return null;
    const encryptExpiry = encryptionKey instanceof Key
      ? (await encryptionKey.getExpirationTime(userId))!
      : getSubkeyExpirationTime(encryptionKey) ;
    if (encryptExpiry < expiry) expiry = encryptExpiry;
  }
  if (capabilities === 'sign' || capabilities === 'encrypt_sign') {
    const signatureKey = (await key.getSigningKey(keyId, new Date(expiry), userId))
      || (await key.getSigningKey(keyId, null, userId));
    if (!signatureKey) return null;
    const signExpiry = signatureKey instanceof Key
      ? (await signatureKey.getExpirationTime(userId))!
      : await getSubkeyExpirationTime(signatureKey);
    if (signExpiry < expiry) expiry = signExpiry;
  }
  return expiry;
}
