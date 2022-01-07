/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Api } from './lib/api';
import * as http from 'http';
import { getMockAttesterEndpoints } from './apis/attester/attester-endpoints';
import { getMockGoogleEndpoints } from './apis/google/google-endpoints';
import { getMockEkmEndpoints } from './apis/ekm/ekm-endpoints';
import { getMockWkdEndpoints } from './apis/wkd/wkd-endpoints';
import { getMockFesEndpoints } from './apis/fes/fes-endpoints';
import { AttesterConfig, EkmConfig, FesConfig, GoogleConfig, Logger, MockConfig, WkdConfig } from './lib/configuration-types';

/**
 * const mockApi = new MockApi();
 * mockApi.fesConfiguration = { clientConfiguration: {flags: []} });
 * mockApi.configureAttester = {
 *    enableSubmittingPubkeys: false,
 *    availablePubkeys: {
 *        'recipient@example.com': attesterPublicKeySamples.valid
 *    }
 * };
 * await mockApi.withMockedApis(async () => {
 *    // here goes your test spec code
 *    // later maybe you want to change some config on the fly
 *    mockApi.fesConfiguration = { clientConfiguration: {flags: ['NO_PRV_BACKUP']} });
 *    // now run some more appium code, mock will be serving with updated config
 *    // or let's say you want to one of the mock servers offline
 *    mockApi.fesConfiguration = undefined
 *    // continue testing, mock will be responding HTTP 404 to all requests
 * });
 */
export class MockApi {

  private port = 8001;
  private logger: Logger = console.log // change here to log to a file instead

  public mockConfig: MockConfig = { serverUrl: `http://127.0.0.1:${this.port}` };

  public fesConfig: FesConfig | undefined = undefined;
  public googleConfig: GoogleConfig | undefined = undefined;
  public wkdConfig: WkdConfig | undefined = undefined;
  public ekmConfig: EkmConfig | undefined = undefined;
  public attesterConfig: AttesterConfig | undefined = undefined;

  public withMockedApis = async (testRunner: () => Promise<void>) => {
    const logger = this.logger;
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
    ], undefined, false);
    await api.listen(this.port);
    try {
      await testRunner();
    } finally {
      await api.close();
    }
  };

}

