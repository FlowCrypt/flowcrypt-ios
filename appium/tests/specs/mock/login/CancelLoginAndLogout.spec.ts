import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('user should be able to cancel login + login + logout', async () => {

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com');
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.clickContinueWithGmail();
      await SplashScreen.clickCancelButton();
      await SplashScreen.checkLoginPage();

      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickLogout();
      await SplashScreen.checkLoginPage();
    });
  });
});
