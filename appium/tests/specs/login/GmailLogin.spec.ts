import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  CreateKeyScreen,
  MenuBarScreen
} from '../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('user is able to login via gmail + test running mocks', async () => {
    const mockApi = new MockApi();
    // testing MockApi integration. For now the mock api starts and stops, 
    //   but it is not used by the app yet. App still communicates to
    //   live APIs until we finish the integration on app side.
    mockApi.fesConfig = { clientConfiguration: { key_manager_url: 'INTENTIONAL BAD URL' } };
    await mockApi.withMockedApis(async () => {

      await SplashScreen.login();
      await CreateKeyScreen.setPassPhrase();

      await MenuBarScreen.clickMenuIcon();
      await MenuBarScreen.checkUserEmail();
      await MenuBarScreen.checkMenuBar();

      await MenuBarScreen.clickLogout();
      await SplashScreen.checkLoginPage();

    });
  });
});
