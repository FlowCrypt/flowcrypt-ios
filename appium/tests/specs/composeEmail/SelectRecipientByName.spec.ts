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

        const firstContactEmail = CommonData.contact.email;
        const firstContactName = CommonData.contact.name;

        const secondContactEmail = CommonData.secondContact.email;
        const secondContactName = CommonData.secondContact.name;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        // Go to Contacts screen
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

        // Add first contact
        InboxScreen.clickCreateEmail();

        NewMessageScreen.setAddRecipientByName(firstContactName, firstContactEmail);
        NewMessageScreen.checkAddedRecipient(firstContactEmail);
        NewMessageScreen.clickBackButton();

        // Add second contact
        InboxScreen.clickCreateEmail();

        NewMessageScreen.setAddRecipientByName(secondContactName, secondContactEmail);
        NewMessageScreen.checkAddedRecipient(secondContactEmail);
        NewMessageScreen.clickBackButton();        

        // Go to Contacts screen
        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.checkUserEmail();

        MenuBarScreen.clickSettingsButton();
        SettingsScreen.checkSettingsScreen();
        SettingsScreen.clickOnSettingItem('Contacts');

        ContactScreen.checkContactScreen();
        ContactScreen.checkContact(firstContactEmail);
        ContactScreen.checkContact(secondContactEmail);
        ContactScreen.clickOnContact(firstContactEmail);

        ContactPublicKeyScreen.checkPgpUserId(firstContactEmail);
        ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
        ContactPublicKeyScreen.clickOnFingerPrint();
        ContactPublicKeyScreen.checkPublicKeyNotEmpty();
    });
});
