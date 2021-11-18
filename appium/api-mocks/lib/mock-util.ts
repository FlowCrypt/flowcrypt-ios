/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { IncomingMessage } from 'http';
import { HttpClientErr } from './api';
import * as request from 'request';

export const isGet = (r: IncomingMessage) => r.method === 'GET' || r.method === 'HEAD';
export const isPost = (r: IncomingMessage) => r.method === 'POST';
export const isPut = (r: IncomingMessage) => r.method === 'PUT';
export const isDelete = (r: IncomingMessage) => r.method === 'DELETE';
export const parseResourceId = (url: string) => url.match(/\/([a-zA-Z0-9\-_]+)(\?|$)/)![1];

export const expectContains = (haystack: unknown, needle: string) => {
  if (!String(haystack).includes(needle)) {
    throw new Error(`MockApi expectations unmet: expected "${haystack}" to contain "${needle}"`);
  }
};

export const throwIfNotGetMethod = (req: IncomingMessage) => {
  if (req.method !== 'GET') {
    throw new HttpClientErr('Unsupported method');
  }
}

export const lousyRandom = () => Math.random().toString(36).substring(2);





export class RequestsError extends Error {
  public reason: unknown;
  constructor(reason: unknown) {
    super();
    this.reason = reason;
  }
}

export class Requests {
  public static get = (
    options: (request.UriOptions & request.CoreOptions) | (request.UrlOptions & request.CoreOptions)
  ): Promise<request.Response> => new Promise((resolve, reject) => {
    request.get(options, (e, resp) => e ? reject(new RequestsError(e)) : resolve(resp));
  });
}
