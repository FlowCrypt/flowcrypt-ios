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
      // todo - await modal
    });
  });
});
