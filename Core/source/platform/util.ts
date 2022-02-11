/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from '../core/buf';
import { randomBytes } from 'crypto';
import { ConvertStringOptions } from 'encoding-japanese';
import { Key, KeyID, UserID } from 'openpgp';

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

export const getExpirationTimeForCapability = async (
  key: Key, capabilities: string, keyId?: KeyID | undefined, userId?: UserID | undefined)
    : Promise<Date | null | typeof Infinity> => {
  const primaryUser = await key.getPrimaryUser(undefined, userId, undefined);
  if (!primaryUser) throw new Error('Could not find primary user');
  const keyExpiry = await key.getExpirationTime(userId);
  if (!keyExpiry) return Infinity;
  let sigExpiry: Date | number | null = null;
  for (const exp of primaryUser.user.selfCertifications.map(selfCert => selfCert.getExpirationTime())) {
    if (sigExpiry == null || exp < sigExpiry!) sigExpiry = exp;
  }
  let expiry = sigExpiry == null || keyExpiry < sigExpiry! ? keyExpiry : sigExpiry;
  if (capabilities === 'encrypt' || capabilities === 'encrypt_sign') {
    const encryptKey = (await key.getEncryptionKey(keyId, new Date(expiry), userId))
      || (await key.getEncryptionKey(keyId, null, userId));
    if (!encryptKey) return null;
    const encryptExpiry = await encryptKey.getExpirationTime(userId);
    if (encryptExpiry < expiry) expiry = encryptExpiry;
  }
  if (capabilities === 'sign' || capabilities === 'encrypt_sign') {
    const signKey = (await key.getSigningKey(keyId, new Date(expiry), userId))
      || (await key.getSigningKey(keyId, null, userId));
    if (!signKey) return null;
    const signExpiry = await signKey.getExpirationTime(key.keyPacket);
    if (signExpiry < expiry) expiry = signExpiry;
  }
  return expiry;
}
