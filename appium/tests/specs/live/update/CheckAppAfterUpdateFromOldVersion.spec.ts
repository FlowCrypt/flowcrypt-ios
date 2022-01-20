import {
    SplashScreen,
    SetupKeyScreen,
    MenuBarScreen,
    MailFolderScreen,
    EmailScreen,
    OldVersionAppScreen,
    SettingsScreen,
    KeysScreen,
    PublicKeyScreen,
    ContactScreen,
    ContactPublicKeyScreen,
    SearchScreen,
    PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';
import {CommonData} from "../../../data";

describe('UPDATE: ', () => {

  it('user should be able to check encrypted email, contacts after update app from old version', async () => {

    const oldAppPath = CommonData.appPath.old;
    const newAppPath = CommonData.appPath.new;
    const bundleId = CommonData.bundleId.id;
    const correctPassPhrase = CommonData.account.passPhrase;
    const firstContactItemName = 'Dmitry at FlowCrypt';
    const firstContactEmail = CommonData.contact.email;
    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmail.subject;
    const emailText = CommonData.encryptedEmail.message;

    //terminate current app version
    await driver.terminateApp(bundleId);
    //remove current app version
    await driver.removeApp(bundleId);
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
    await OldVersionAppScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await OldVersionAppScreen.clickBackButton();

    await OldVersionAppScreen.clickBackButton();

    await MenuBarScreen.clickMenuIcon();
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
    await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();

    //close old app version
    await driver.terminateApp(bundleId);

    //update/install new app version
    await driver.installApp(newAppPath);
    //run new app
    await driver.activateApp(bundleId);

    await MailFolderScreen.checkInboxScreen();
    await MenuBarScreen.clickMenuIcon();
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

    await KeysScreen.checkKeysScreen();
    await KeysScreen.clickOnKey();

    await KeysScreen.checkSelectedKeyScreen();

    await KeysScreen.clickOnShowPublicKey();
    await PublicKeyScreen.checkPublicKey();
    await PublicKeyScreen.clickBackButton();

    await KeysScreen.checkSelectedKeyScreen();
    await KeysScreen.clickBackButton();

    await KeysScreen.checkKeysScreen();
    await KeysScreen.clickBackButton();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkMenuBar();

    await MenuBarScreen.clickInboxButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.enterPassPhrase(correctPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
