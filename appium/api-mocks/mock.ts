/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Api } from './lib/api';
import * as http from 'http';
import { attesterPublicKeySamples, getMockAttesterEndpoints } from './apis/attester/attester-endpoints';
import { getMockGoogleEndpoints } from './apis/google/google-endpoints';
import { ekmKeySamples, getMockEkmEndpoints } from './apis/ekm/ekm-endpoints';
import { getMockWkdEndpoints } from './apis/wkd/wkd-endpoints';
import { getMockFesEndpoints } from './apis/fes/fes-endpoints';
import { AttesterConfig, EkmConfig, FesConfig, GoogleConfig, Logger, MockConfig, WkdConfig } from './lib/configuration-types';
import { readFileSync } from 'fs';
import { CommonData } from 'tests/data';

/**
 * const mockApi = new MockApi();
 * mockApi.fesConfig = { clientConfiguration: {flags: []} });
 * mockApi.attesterConfig = {
 *    enableSubmittingPubkeys: false,
 *    availablePubkeys: {
 *        'recipient@example.com': attesterPublicKeySamples.valid
 *    }
 * };
 * await mockApi.withMockedApis(async () => {
 *    // here goes your test spec code
 *    // later maybe you want to change some config on the fly
 *    mockApi.fesConfig = { clientConfiguration: {flags: ['NO_PRV_BACKUP']} });
 *    // now run some more appium code, mock will be serving with updated config
 *    // or let's say you want to one of the mock servers offline
 *    mockApi.fesConfig = undefined
 *    // continue testing, mock will be responding HTTP 404 to all requests
 * });
 */
export class MockApi {

  private port = 8001;
  private logger: Logger = console.log // change here to log to a file instead

  public mockConfig: MockConfig = { serverUrl: `https://127.0.0.1:${this.port}` };

  public fesConfig: FesConfig | undefined = undefined;
  public googleConfig: GoogleConfig | undefined = undefined;
  public wkdConfig: WkdConfig | undefined = undefined;
  public ekmConfig: EkmConfig | undefined = undefined;
  public attesterConfig: AttesterConfig | undefined = undefined;

  public withMockedApis = async (testRunner: () => Promise<void>) => {
    const logger = this.logger;

    const base64 = readFileSync('./api-mocks/mock-ssl-cert/cert.pem.mock').toString('base64');
    await driver.execute('mobile: installCertificate', { content: base64 })

    class LoggedApi<REQ, RES> extends Api<REQ, RES> {
      protected throttleChunkMsUpload = 5;
      protected throttleChunkMsDownload = 10;
      protected log = (ms: number, req: http.IncomingMessage, res: http.ServerResponse, errRes?: Buffer) => {
        logger(`${ms}ms | ${res.statusCode} ${req.method} ${req.url} | ${errRes ? errRes : ''}`);
      }
    }
    const api = new LoggedApi<{ query: { [k: string]: string }, body?: unknown }, unknown>('api-mock', [
      () => getMockFesEndpoints(this.mockConfig, this.fesConfig),
      () => getMockAttesterEndpoints(this.mockConfig, this.attesterConfig),
      () => getMockGoogleEndpoints(this.mockConfig, this.googleConfig),
      () => getMockEkmEndpoints(this.mockConfig, this.ekmConfig),
      () => getMockWkdEndpoints(this.mockConfig, this.wkdConfig),
    ], undefined, true);
    await api.listen(this.port);
    try {
      await testRunner();
    } finally {
      await api.close();
    }
  };

  static get e2eMock() {
    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv, ekmKeySamples.e2e.prv, ekmKeySamples.key1.prv]
    }
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [
            { displayName: CommonData.contact.contactName, email: CommonData.contact.email },
            { displayName: CommonData.secondContact.contactName, email: CommonData.secondContact.email },
            { displayName: CommonData.recipient.name, email: CommonData.recipient.email },
            { displayName: CommonData.expiredMockUser.name, email: CommonData.expiredMockUser.email },
            { displayName: CommonData.alias.name, email: CommonData.alias.email }
          ],
          messages: ['CC and BCC test', 'Test 1', 'Signed and encrypted message', 'Signed only message', 'Signed only message with detached signature', 'Signed only message where the pubkey is not available', 'Signed only message that was tempered during transit', 'Partially signed only message', 'Honor reply-to address - plain', 'email with text attachment', 'Message with cc and multiple recipients and text attachment', 'new message for reply', 'encrypted - MDC hash mismatch - modification detected - should fail', 'message encrypted for another public key (only one pubkey used)', 'wrong checksum', 'not integrity protected - should show a warning and not decrypt automatically', 'key mismatch unexpectedly produces a modal', 'test thread rendering', 'Archived thread'],
        }
      }
    }
    mockApi.attesterConfig = {
      servedPubkeys: {
        'expired@flowcrypt.com': attesterPublicKeySamples.expiredFlowcrypt,
        'revoked@flowcrypt.com': attesterPublicKeySamples.revoked,
        'robot@flowcrypt.com': attesterPublicKeySamples.robot,
        'test2@example.net': attesterPublicKeySamples.valid,
        'dmitry@flowcrypt.com': ekmKeySamples.dmitry.pub!,
        'valid@domain.test': attesterPublicKeySamples.valid,
        'expired@domain.test': attesterPublicKeySamples.expired,
        'e2e.enterprise.test@flowcrypt.com': ekmKeySamples.e2e.pub!,
        'demo@flowcrypt.com': ekmKeySamples.demoUser.pub!,
        'flowcrypt.compatibility@gmail.com': ekmKeySamples.flowcryptCompabilityOther.pub!,
        'ioan@flowcrypt.com': ekmKeySamples.ioan.pub!,
        'sunitnandi834@gmail.com': ekmKeySamples.sunit.pub!
      }
    };
    mockApi.wkdConfig = {}
    return mockApi
  }
}

