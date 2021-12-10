import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('user should be able to cancel login + login + logout', async () => {

    await SplashScreen.clickContinueWithGmail();
    await SplashScreen.clickCancelButton();
    await SplashScreen.checkLoginPage();

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickLogout();
    await SplashScreen.checkLoginPage();
  });
});
