/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Endpoints } from './mobile-interface/endpoints';
import { fmtErr } from './mobile-interface/format-output';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const global: any;

global.handleRequestFromHost = async (endpointName: string, request: string, data: Uint8Array) => {
  const endpoints = new Endpoints();
  try {
    const handler = endpoints[endpointName];
    if (!handler) {
      return fmtErr(new Error(`Unknown endpoint: ${endpointName}`));
    } else {
      return handler(request, [data])
        .then(res => res)
        .catch(err => fmtErr(err as Error));
    }
  } catch (err) {
    return fmtErr(err as Error);
  }
};
