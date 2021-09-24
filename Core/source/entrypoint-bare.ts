/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

/// <reference path="./core/types/openpgp.d.ts" />

'use strict';

import { Buf } from './core/buf';
import { Endpoints } from './mobile-interface/endpoints';
import { fmtErr } from './mobile-interface/format-output';

declare const global: any;

const endpoints = new Endpoints();

const formatBareOutput = (res: Buf) => res.toBase64Str();

global.handleRequestFromHost = (endpointName: string, request: string, data: string, cb: (b64response: string) => void): void => {
  try {
    const handler = endpoints[endpointName];
    if (!handler) {
      cb(formatBareOutput(fmtErr(new Error(`Unknown endpoint: ${endpointName}`))));
    } else {
      handler(JSON.parse(request), [Buf.fromBase64Str(data)])
        .then(res => cb(formatBareOutput(Buf.concat(res))))
        .catch(err => cb(formatBareOutput(fmtErr(err))));
    }
  } catch (err) {
    cb(formatBareOutput(fmtErr(err)));
  }
};
