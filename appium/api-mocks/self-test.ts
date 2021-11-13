/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { MockApiSetup } from './mock-api-setup';

(async () => {
  // here we run some smoke tests on the mock api to make sure it functions well
  const mockApiSetup = new MockApiSetup();
  mockApiSetup.configureFes({
    clientConfiguration: { flags: [] }
  });
  await mockApiSetup.start();


  // end of tests
})().catch(e => {
  console.error(`Unhandled exception when running mock: ${String(e)}`);
  if (e instanceof Error) {
    console.error(e.stack);
  }
  process.exit(1);
})

