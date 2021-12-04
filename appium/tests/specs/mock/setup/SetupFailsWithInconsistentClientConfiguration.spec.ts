import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  // SetupKeyScreen,
} from '../../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('app setup fails with bad EKM URL', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = { clientConfiguration: { key_manager_url: 'INTENTIONAL BAD URL' } };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      // todo - replace the following pause with wait for modal error
      //   that says "Please check if key manager url set correctly"
      await browser.pause(5000);
    });
  });

  it('setup shows meaningful error when FES returns 400', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = { returnError: { code: 400, message: "some client err" } };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      // todo - replace the following pause with wait for modal error
      await browser.pause(5000);
    });
  });

  // todo - app shows meaningful error when FES returns wrong err format

});
