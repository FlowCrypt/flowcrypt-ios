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

  it('check recipient color after removing public key from settings', async () => {

    const contactEmail = CommonData.contact.email;
    const contactName = CommonData.contact.name;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Add first contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(contactName, contactEmail);
    await NewMessageScreen.checkAddedRecipientColor(contactEmail, 0, 'green');
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(contactEmail);

    await ContactScreen.clickOnContact(contactEmail);
    await ContactPublicKeyScreen.checkPgpUserId(contactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();

    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();

    await PublicKeyDetailsScreen.clickTrashButton();
    await ContactPublicKeyScreen.checkPgpUserId(contactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotDisplayed();
    await ContactPublicKeyScreen.clickBackButton();

    await ContactScreen.checkContactWithoutPubKey(contactEmail);
    await ContactScreen.clickBackButton();
    await SettingsScreen.checkSettingsScreen();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();
    await MenuBarScreen.clickInboxButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(contactName, contactEmail);
    await NewMessageScreen.checkAddedRecipientColor(contactEmail, 0, 'green');
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(contactEmail);

    await ContactScreen.clickOnContact(contactEmail);
    await ContactPublicKeyScreen.checkPgpUserId(contactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();

    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
  });
});
