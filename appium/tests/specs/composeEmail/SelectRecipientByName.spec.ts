import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  NewMessageScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SettingsScreen,
  MenuBarScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to select recipient from contact list using contact name', async () => {

    const firstContactEmail = CommonData.contact.email;
    const firstContactName = CommonData.contact.name;
    const firstContactItemName = 'Dmitry at FlowCrypt';

    const secondContactEmail = CommonData.secondContact.email;
    const secondContactName = CommonData.secondContact.name;
    const secondContactItemName = 'Demo key 2';

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await InboxScreen.checkInboxScreen();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkEmptyList();
    await ContactScreen.clickBackButton();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickInboxButton();
    await InboxScreen.checkInboxScreen();

    // Add first contact
    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(firstContactName, firstContactEmail);
    await NewMessageScreen.checkAddedRecipient(firstContactEmail);
    await NewMessageScreen.clickBackButton();

    // Add second contact
    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(secondContactName, secondContactEmail);
    await NewMessageScreen.checkAddedRecipient(secondContactEmail);
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(firstContactItemName);
    await ContactScreen.checkContact(secondContactItemName);

    // Go to Contact screen
    await ContactScreen.clickOnContact(firstContactItemName);

    await ContactPublicKeyScreen.checkPgpUserId(firstContactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();
    await ContactPublicKeyScreen.checkPublicKeyNotEmpty();
  });
});
