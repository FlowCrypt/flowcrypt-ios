import MailFolderScreen from '../screenobjects/mail-folder.screen';
import NewMessageScreen from '../screenobjects/new-message.screen';
import MenuBarScreen from '../screenobjects/menu-bar.screen';
import SettingsScreen from '../screenobjects/settings.screen';
import ContactScreen from '../screenobjects/contacts.screen';
import ContactPublicKeyScreen from '../screenobjects/contact-public-key.screen';
import PublicKeyDetailsScreen from '../screenobjects/public-key-details.screen';
import DataHelper from './DataHelper';

interface PublicKeyDetailToCheck {
  fingerprintsValue?: string;
  signatureDate?: string;
  recipientName?: string;
  expiryDate?: string;
  shouldDeleteKey?: boolean;
  publicKeyCount?: number;
}
class PublicKeyHelper {
  static loadRecipientInComposeThenCheckKeyDetails = async (
    userEmail: string,
    goBackToMainScreen = false,
    detailToCheck?: PublicKeyDetailToCheck,
  ) => {
    const { recipientName, fingerprintsValue, signatureDate, expiryDate, shouldDeleteKey, publicKeyCount } =
      detailToCheck ?? {};
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
    if (publicKeyCount) {
      await ContactPublicKeyScreen.checkPublicKeyCount(publicKeyCount);
    }
    await ContactPublicKeyScreen.clickOnFingerPrint();

    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
    if (signatureDate) {
      await PublicKeyDetailsScreen.checkSignatureDateValue(signatureDate);
    }
    if (fingerprintsValue) {
      await PublicKeyDetailsScreen.checkFingerPrintsValue(fingerprintsValue);
    }
    if (expiryDate) {
      await PublicKeyDetailsScreen.checkExpiredValue(expiryDate);
    }
    const lastFetchedDate = DataHelper.convertStringToDate(
      await PublicKeyDetailsScreen.getLastFetchedDateValue(),
    ).valueOf();
    if (goBackToMainScreen) {
      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      if (shouldDeleteKey) {
        await ContactPublicKeyScreen.clickTrashButton();
      } else {
        await ContactPublicKeyScreen.clickBackButton();
      }

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
    }
    return lastFetchedDate;
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
