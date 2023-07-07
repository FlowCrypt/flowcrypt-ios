import MailFolderScreen from '../screenobjects/mail-folder.screen';
import NewMessageScreen from '../screenobjects/new-message.screen';
import MenuBarScreen from '../screenobjects/menu-bar.screen';
import SettingsScreen from '../screenobjects/settings.screen';
import ContactScreen from '../screenobjects/contacts.screen';
import ContactPublicKeyScreen from '../screenobjects/contact-public-key.screen';
import PublicKeyDetailsScreen from '../screenobjects/public-key-details.screen';

class PublicKeyHelper {
  static loadRecipientInComposeThenCheckSignatureAndFingerprints = async (
    userEmail: string,
    signatureDate: string,
    fingerprintsValue: string,
    recipientName?: string,
  ) => {
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipient(userEmail);
    await NewMessageScreen.checkAddedRecipient(recipientName ?? userEmail);
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(userEmail);

    await ContactScreen.clickOnContact(userEmail);
    await ContactPublicKeyScreen.checkPgpUserId(userEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();

    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
    await PublicKeyDetailsScreen.checkSignatureDateValue(signatureDate);
    await PublicKeyDetailsScreen.checkFingerPrintsValue(fingerprintsValue);
  };
  static addRecipientAndCheckFetchedKey = async (userName: string, userEmail: string) => {
    // Add first contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipientByName(userName, userEmail);
    await NewMessageScreen.checkAddedRecipientColor(userName, 0, 'green');
    await NewMessageScreen.clickBackButton();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(userEmail);

    await ContactScreen.clickOnContact(userEmail);
    await ContactPublicKeyScreen.checkPgpUserId(userEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();

    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
  };
}

export default PublicKeyHelper;
