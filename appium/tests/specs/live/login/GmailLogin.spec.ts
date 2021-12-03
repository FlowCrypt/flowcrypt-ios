import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';


describe('LOGIN: ', () => {

  it('user is able to login via gmail', async () => {
    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickLogout();
    await SplashScreen.checkLoginPage();
  });
});
