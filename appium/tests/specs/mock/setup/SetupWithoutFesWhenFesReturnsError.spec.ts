import { MockApi } from 'api-mocks/mock';
import { SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('SETUP: ', () => {
  it('enterprise app allows setup without FES when FES returns 404', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = {
      returnError: {
        code: 404,
        message: 'on error 404 app should act like there is no FES',
      },
    };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.checkNoBackupsFoundScreen();
    });
  });
});
