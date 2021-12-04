import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';


describe('SETUP: ', () => {

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

});
