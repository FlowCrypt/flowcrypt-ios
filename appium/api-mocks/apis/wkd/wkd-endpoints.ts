/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { HandlersDefinition, HttpErr } from '../../lib/api';
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
    '/.well-known/openpgpkey/hu/?': async () => {
      return { "code": 404, "message": "Public key not found", "details": "" }
    },
    '/.well-known/openpgpkey/127.0.0.1:8001/policy': async () => {
      return ''; // allow advanced for localhost
    },
    '/.well-known/openpgpkey/policy': async () => {
      return ''; // allow direct for all
    },
  };
}