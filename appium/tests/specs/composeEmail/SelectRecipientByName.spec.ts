import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen,
    ContactScreen,
    ContactPublicKeyScreen,
    SettingsScreen,
    MenuBarScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('user is able to select recipient from contact list using contact name', () => {

        const contactEmail = CommonData.contact.email;
        const contactName = CommonData.contact.name;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail();

        MenuBarScreen.clickSettingsButton();
        SettingsScreen.checkSettingsScreen();
        SettingsScreen.clickOnSettingItem('Contacts');

        ContactScreen.checkContactScreen();
        ContactScreen.checkEmptyList();
        ContactScreen.clickBackButton();

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.clickInboxButton();

        InboxScreen.clickCreateEmail();

        NewMessageScreen.setAddRecipientByName(contactName, contactEmail);
        NewMessageScreen.checkAddedRecipient(contactEmail);
        NewMessageScreen.clickBackButton();

        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail();

        MenuBarScreen.clickSettingsButton();
        SettingsScreen.checkSettingsScreen();
        SettingsScreen.clickOnSettingItem('Contacts');

        ContactScreen.checkContactScreen();
        ContactScreen.checkContact(contactEmail);
        ContactScreen.clickOnContact(contactEmail);

        ContactPublicKeyScreen.checkUser(contactEmail);
        ContactPublicKeyScreen.checkContactPublicKey();
        ContactPublicKeyScreen.clickOnFingerPrint();
        ContactPublicKeyScreen.checkPublicKey();
    });
});
