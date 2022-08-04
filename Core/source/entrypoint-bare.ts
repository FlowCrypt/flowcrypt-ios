/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Endpoints } from './mobile-interface/endpoints';
import { EndpointRes, fmtErr } from './mobile-interface/format-output';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const global: any;

const endpoints = new Endpoints();

global.handleRequestFromHost = (
  endpointName: string, callbackId: string, request: string,
  data: Uint8Array, cb: (key: string, response: EndpointRes) => void): void => {
  try {
    const handler = endpoints[endpointName];
    if (!handler) {
      cb(callbackId, fmtErr(new Error(`Unknown endpoint: ${endpointName}`)));
    } else {
      handler(JSON.parse(request), [data])
        .then(res => cb(callbackId, res))
        .catch(err => cb(callbackId, fmtErr(err as Error)));
    }
  } catch (err) {
    cb(callbackId, fmtErr(err as Error));
  }
};
