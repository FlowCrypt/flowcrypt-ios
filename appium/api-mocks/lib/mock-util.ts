/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { IncomingMessage } from 'http';
import { HttpClientErr } from './api';

export const isGet = (r: IncomingMessage) => r.method === 'GET' || r.method === 'HEAD';
export const isPost = (r: IncomingMessage) => r.method === 'POST';
export const isPut = (r: IncomingMessage) => r.method === 'PUT';
export const isDelete = (r: IncomingMessage) => r.method === 'DELETE';
export const parseResourceId = (url: string) => url.match(/\/([a-zA-Z0-9\-_]+)(\?|$)/)![1];

export const expectContains = (haystack: any, needle: string) => {
  if (!String(haystack).includes(needle)) {
    throw new Error(`MockApi expectations unmet: expected "${haystack}" to contain "${needle}"`);
  }
};

export const throwIfNotGetMethod = (req: IncomingMessage) => {
  if (req.method !== 'GET') {
    throw new HttpClientErr('Unsupported method');
  }
}