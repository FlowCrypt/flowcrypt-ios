/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from '../core/buf';
import { randomBytes } from 'crypto';
import { ConvertStringOptions } from 'encoding-japanese';

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

/**
 * Create binary string from a hex encoded string
 * @param {String} str Hex string to convert
 * @returns {String}
 */
export const hex_to_str = (hex: string): string => {
  let str = '';
  for (let i = 0; i < hex.length; i += 2) {
    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
  }
  return str;
}

/**
 * Convert an array of 8-bit integers to a string
 * @param {Uint8Array} bytes An array of 8-bit integers to convert
 * @returns {String} String representation of the array
 */
export const Uint8Array_to_str = (bytes: Uint8Array): string => {
  bytes = new Uint8Array(bytes);
  const result = [];
  const bs = 1 << 14;
  const j = bytes.length;

  for (let i = 0; i < j; i += bs) {
    result.push(String.fromCharCode.apply(String, bytes.subarray(i, i + bs < j ? i + bs : j)));
  }
  return result.join('');
}
