/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

/// <reference path="./core/types/openpgp.d.ts" />

'use strict';

import { Buf } from './core/buf';
import { Endpoints } from './mobile-interface/endpoints';
import { EndpointRes, fmtErr } from './mobile-interface/format-output';

declare const global: any;

const endpoints = new Endpoints();

global.handleRequestFromHost = (endpointName: string, request: string, data: string, cb: (response: EndpointRes) => void): void => {
  try {
    const handler = endpoints[endpointName];
    if (!handler) {
      cb(fmtErr(new Error(`Unknown endpoint: ${endpointName}`)));
    } else {
      handler(JSON.parse(request), [Buf.fromBase64Str(data)])
        .then(res => cb(res))
        .catch(err => cb(fmtErr(err)));
    }
  } catch (err) {
    cb(fmtErr(err));
  }
};
