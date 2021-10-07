
import {
    SplashScreen,
    CreateKeyScreen,
    MenuBarScreen
} from '../../screenobjects/all-screens';

import commonData from '../../data/index';

describe('LOGIN: ', () => {

    it('user is able to login via gmail', () => {

        const email = commonData.account.email;
        const pass = commonData.account.password;
        const passPhrase = commonData.account.passPhrase;

        SplashScreen.login(email, pass);
        CreateKeyScreen.setPassPhrase(passPhrase);

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail(email);
        MenuBarScreen.checkMenuBar();

        MenuBarScreen.clickLogout();
        SplashScreen.checkLoginPage();
    });
});
