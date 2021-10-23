/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from '../core/buf';
import { randomBytes } from 'crypto';

interface ConvertStringOptions {
  to: string;
  from?: string | undefined;
  type: 'string';
  bom?: boolean | string | undefined;
}

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
