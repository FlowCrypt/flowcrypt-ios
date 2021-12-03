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
      await browser.pause(10000);
      // todo - currently this passes because we are not testing the desired result yet
      //   it logs in and shows a "network lost" but should be showing a more specific modal
      //   mock is not reached yet probably due to app security settings (plain http)
    });
  });
});
