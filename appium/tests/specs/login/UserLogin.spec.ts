import {
    SplashScreen,
    CreateKeyScreen,
    MenuBarScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('LOGIN: ', () => {

    it('user is able to login via gmail', () => {

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail();
        MenuBarScreen.checkMenuBar();

        MenuBarScreen.clickLogout();
        SplashScreen.checkLoginPage();
    });
});
