/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Api } from './lib/api';
import * as http from 'http';
import { getMockAttesterEndpoints } from './apis/attester/attester-endpoints';
import { getMockGoogleEndpoints } from './apis/google/google-endpoints';
import { getMockEkmEndpoints } from './apis/ekm/ekm-endpoints';
import { getMockWkdEndpoints } from './apis/wkd/wkd-endpoints';
import { getMockFesEndpoints } from './apis/fes/fes-endpoints';
import { AttesterConfig, EkmConfig, FesConfig, GoogleConfig, GoogleMockAccount, Logger, MockConfig, WkdConfig } from './lib/configuration-types';
import { readFileSync } from 'fs';
import { GoogleMockAccountEmail } from './apis/google/google-messages';

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

  private _mockConfig: MockConfig = { serverUrl: `https://127.0.0.1:${this.port}` };

  private _fesConfig: FesConfig | undefined = undefined;
  private _googleConfig: GoogleConfig | undefined = undefined;
  private _wkdConfig: WkdConfig | undefined = undefined;
  private _ekmConfig: EkmConfig | undefined = undefined;
  private _attesterConfig: AttesterConfig | undefined = undefined;

  public set fesConfig(config: FesConfig) {
    this._fesConfig = config;
  }

  public set wkdConfig(config: WkdConfig) {
    this._wkdConfig = config;
  }

  public set ekmConfig(config: EkmConfig) {
    this._ekmConfig = config;
  }

  public set attesterConfig(config: AttesterConfig) {
    this._attesterConfig = config;
  }

  public addGoogleAccount(email: GoogleMockAccountEmail, account: GoogleMockAccount = {}) {
    if (!this._googleConfig) {
      this._googleConfig = {
        accounts: {
          [email]: account
        }
      }
    } else {
      this._googleConfig.accounts[email] = account;
    }
  }

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
      () => getMockFesEndpoints(this._mockConfig, this._fesConfig),
      () => getMockAttesterEndpoints(this._mockConfig, this._attesterConfig),
      () => getMockGoogleEndpoints(this._mockConfig, this._googleConfig),
      () => getMockEkmEndpoints(this._mockConfig, this._ekmConfig),
      () => getMockWkdEndpoints(this._mockConfig, this._wkdConfig),
    ], undefined, true);
    await api.listen(this.port);
    try {
      await testRunner();
    } finally {
      await api.close();
    }
  };
}

