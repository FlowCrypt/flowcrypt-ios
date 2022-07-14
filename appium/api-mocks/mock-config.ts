import { EkmConfig, FesConfig } from './lib/configuration-types';
import { ekmKeySamples } from './apis/ekm/ekm-endpoints';
import { CommonData } from '../tests/data';

export class MockApiConfig {
  static get defaultEnterpriseEkmConfiguration(): EkmConfig {
    return {
      returnKeys: [ekmKeySamples.key0.prv, ekmKeySamples.e2e.prv, ekmKeySamples.key1.prv]
    };
  }

  static get defaultEnterpriseFesConfiguration(): FesConfig {
    return {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
  }
}