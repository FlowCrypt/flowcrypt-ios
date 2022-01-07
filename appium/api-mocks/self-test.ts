/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Requests } from './lib/mock-util';
import { MockApi } from './mock';

class TestFailed extends Error { }

(async () => {
  // here we run some smoke tests on the mock api to make sure it functions well
  const mockApi = new MockApi();
  mockApi.fesConfig = { clientConfiguration: { flags: ['NO_PRV_BACKUP'] } };
  const fesEndpoint = `${mockApi.mockConfig.serverUrl}/api/v1/client-configuration?domain=example.test`;
  // before start of API, should get error
  try {
    await Requests.get({ url: fesEndpoint });
    throw new TestFailed("expected request to fail before mock started");
  } catch (error) {
    if (error instanceof TestFailed) {
      throw error;
    }
  }
  await mockApi.withMockedApis(async () => {
    const r = await Requests.get({ url: fesEndpoint });
    if (r.body !== '{"clientConfiguration":{"flags":["NO_PRV_BACKUP"]}}') {
      throw new Error(`Unexpected response from MockApi FES: ${r.body}`);
    }
  });
  try {
    await Requests.get({ url: fesEndpoint });
    throw new TestFailed("expected request to fail after mock has finished");
  } catch (error) {
    if (error instanceof TestFailed) {
      throw error;
    }
  }
  // end of tests
})().catch(e => {
  console.error(`Unhandled exception when running mock: ${String(e)}`);
  if (e instanceof Error) {
    console.error(e.stack);
  }
  process.exit(1);
})

