import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';


describe('SETUP: ', () => {

  it('setup shows meaningful error when FES returns 400', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = { returnError: { code: 400, message: "some client err" } };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      // todo - replace the following pause with wait for modal error
      await browser.pause(5000);
    });
  });

});
