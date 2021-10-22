import {
    SplashScreen,
    CreateKeyScreen,
    MenuBarScreen,
    SettingsScreen,
    KeysScreen,
    PublicKeyScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('SETTINGS: ', () => {

    it('user should see public key and should not see private key', () => {

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail();
        MenuBarScreen.checkMenuBar();

        MenuBarScreen.clickSettingsButton();
        SettingsScreen.checkSettingsScreen();
        SettingsScreen.clickOnSettingItem('Keys');

        KeysScreen.checkKeysScreen();
        KeysScreen.clickOnKey();

        KeysScreen.checkSelectedKeyScreen();

        KeysScreen.clickOnShowPublicKey();
        PublicKeyScreen.checkPublicKey();

    });
});
