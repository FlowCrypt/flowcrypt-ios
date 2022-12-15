import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  MailFolderScreen,
  EmailScreen,
  SettingsScreen,
  KeysScreen,
  PublicKeyScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SearchScreen,
  PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';
import MailFolderHelper from "../../../helpers/MailFolderHelper";
import { CommonData } from "../../../data";

describe('UPDATE: ', () => {

  it('user should be able to check encrypted email, contacts after update app from old version', async () => {

    const oldAppPath = CommonData.appPath.old;
    const newAppPath = CommonData.appPath.new;
    const bundleId = CommonData.bundleId.id;
    const correctPassPhrase = CommonData.account.passPhrase;
    const firstContactItemName = CommonData.contact.name;
    const firstContactEmail = CommonData.contact.email;
    const senderName = CommonData.sender.name;
    const emailSubject = CommonData.encryptedEmail.subject;
    const emailText = CommonData.encryptedEmail.message;
    const liveKeys = [ekmKeySamples.e2e, ekmKeySamples.flowcryptCompabilityOther, ekmKeySamples.flowcryptCompability];
    const firstEmailSubject = CommonData.simpleEmail.subject;

    //terminate current app version
    await driver.terminateApp(bundleId);
    //remove current app version
    await driver.removeApp(bundleId);
    //reset keychain
    await driver.execute('mobile: clearKeychains');
    //install old version
    await driver.installApp(oldAppPath);
    //run old app
    await driver.activateApp(bundleId);
    //login and check user
    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
    await EmailScreen.clickBackButton();

    await SearchScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkMenuBar();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');
    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(firstContactItemName);

    await ContactScreen.clickOnContact(firstContactItemName);

    await ContactPublicKeyScreen.checkPgpUserId(firstContactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();
    await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();

    //close old app version
    await driver.terminateApp(bundleId);

    //update/install new app version
    await driver.installApp(newAppPath);
    //run new app
    await driver.activateApp(bundleId);

    await MailFolderScreen.checkInboxScreen();
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();
    await MenuBarScreen.clickSettingsButton();

    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');
    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContact(firstContactItemName);

    await ContactScreen.clickOnContact(firstContactItemName);

    await ContactPublicKeyScreen.checkPgpUserId(firstContactEmail);
    await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
    await ContactPublicKeyScreen.clickOnFingerPrint();
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();

    await ContactPublicKeyScreen.clickBackButton();
    await ContactPublicKeyScreen.checkPgpUserId(firstContactEmail);
    await ContactPublicKeyScreen.clickBackButton();
    await ContactScreen.checkContact(firstContactItemName);
    await ContactScreen.clickBackButton();
    await SettingsScreen.checkSettingsScreen();

    await SettingsScreen.clickOnSettingItem('Keys');

    await KeysScreen.checkKeysScreen(liveKeys);
    await KeysScreen.clickOnKey();

    await KeysScreen.checkSelectedKeyScreen();

    await KeysScreen.clickOnShowPublicKey();
    await PublicKeyScreen.checkPublicKey();
    await PublicKeyScreen.clickBackButton();

    await KeysScreen.checkSelectedKeyScreen();
    await KeysScreen.clickBackButton();

    await KeysScreen.checkKeysScreen(liveKeys);
    await KeysScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkMenuBar();

    await MenuBarScreen.clickInboxButton();
    await MailFolderScreen.checkInboxScreen();

    // check inbox pagination
    await MailFolderScreen.checkInboxScreen();
    await MailFolderHelper.checkPagination(firstEmailSubject);

    await MailFolderScreen.scrollUpToFirstEmail();
    await MailFolderScreen.refreshMailList();

    await MailFolderHelper.checkPagination(firstEmailSubject);

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.enterPassPhrase(correctPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
  });
});
