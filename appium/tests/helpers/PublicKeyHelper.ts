import MailFolderScreen from "../screenobjects/mail-folder.screen";
import NewMessageScreen from "../screenobjects/new-message.screen";
import MenuBarScreen from "../screenobjects/menu-bar.screen";
import SettingsScreen from "../screenobjects/settings.screen";
import ContactScreen from "../screenobjects/contacts.screen";
import ContactPublicKeyScreen from "../screenobjects/contact-public-key.screen";
import PublicKeyDetailsScreen from "../screenobjects/public-key-details.screen";

class PublicKeyHelper {
 static checkSignatureAndFingerprints = async (userEmail: string, signatureDate: string , fingerprintsValue: string ) => {
   await MailFolderScreen.clickCreateEmail();
   await NewMessageScreen.setAddRecipient(userEmail);
   await NewMessageScreen.checkAddedRecipient(userEmail);
   await NewMessageScreen.clickBackButton();

   // Go to Contacts screen
   await MenuBarScreen.clickMenuIcon();
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
 }
}

export default PublicKeyHelper;
