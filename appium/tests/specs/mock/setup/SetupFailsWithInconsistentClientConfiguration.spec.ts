import { MockApi } from 'api-mocks/mock';
import { SplashScreen } from '../../../screenobjects/all-screens';
import BaseScreen from '../../../screenobjects/base.screen';

describe('SETUP: ', () => {
  it('app setup fails with bad EKM URL', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        key_manager_url: 'INTENTIONAL BAD URL',
      },
    };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await BaseScreen.checkModalMessage('Error\n' + 'Please check if key manager url set correctly');
    });
  });
});
