import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('user should be able to cancel login + login + logout', async () => {

    await MockApi.e2eMock.withMockedApis(async () => {
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
