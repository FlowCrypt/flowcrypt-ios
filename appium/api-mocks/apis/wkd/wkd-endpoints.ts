/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { isGet } from 'api-mocks/lib/mock-util';
import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { MockConfig, WkdConfig } from '../../lib/configuration-types';

export class WkdHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return { // follows WKD error response format
      "code": this.statusCode,
      "message": `message:${this.message}`,
      "details": `details:${this.message}`
    }
  }
}

/**
* Web Key Directory - distributes private keys to users who own them
*/
export const getMockWkdEndpoints = (
  mockConfig: MockConfig,
  wkdConfig: WkdConfig | undefined
): HandlersDefinition => {

  if (!wkdConfig) {
    return {};
  }

  return {
    '/.well-known/openpgpkey/hu/?': async (_, req) => {
      const email = req.url!.split('?l=').pop()!.toLowerCase().trim();
      throwErrorIfConfigSaysSo(wkdConfig);
      if (isGet(req)) {
        const pubkey = (wkdConfig.servedPubkeys || {})[email];
        if (pubkey) {
          return pubkey;
        }
        return { "code": 404, "message": "Public key not found", "details": "" }
      } else {
        throw new WkdHttpErr(`Not implemented: ${req.method}`, Status.BAD_REQUEST);
      }
    },
    '/.well-known/openpgpkey/127.0.0.1:8001/policy': async () => {
      return ''; // allow advanced for localhost
    },
    '/.well-known/openpgpkey/policy': async () => {
      return ''; // allow direct for all
    },
  };
}

const throwErrorIfConfigSaysSo = (config: WkdConfig) => {
  if (config.returnError) {
    throw new WkdHttpErr(config.returnError.message, config.returnError.code);
  }
}