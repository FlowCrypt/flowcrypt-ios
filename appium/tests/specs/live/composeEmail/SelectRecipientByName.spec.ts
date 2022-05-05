import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SettingsScreen,
  MenuBarScreen,
  PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to select recipient from contact list using contact name', async () => {

    const firstContactEmail = CommonData.contact.email;
    const firstContactName = CommonData.contact.contactName;

    const secondContactEmail = CommonData.secondContact.email;
    const secondContactName = CommonData.secondContact.contactName;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkEmptyList();
    await ContactScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.clickInboxButton();
    await MailFolderScreen.checkInboxScreen();

    // Add first contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(firstContactName, firstContactEmail);
    await NewMessageScreen.checkAddedRecipient(firstContactName);
    await NewMessageScreen.clickBackButton();

    // Add second contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(secondContactName, secondContactEmail);
    await NewMessageScreen.checkAddedRecipient(secondContactName);
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(firstContactName);
    await ContactScreen.checkContact(secondContactName);

    // Go to Contact screen
    await ContactScreen.clickOnContact(firstContactName);

    await ContactPublicKeyScreen.checkPgpUserId(firstContactEmail, firstContactName);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();
    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
  });
});
