import { MockApi } from 'api-mocks/mock';
import {
    SplashScreen,
    SetupKeyScreen,
    MailFolderScreen,
    NewMessageScreen,
    PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';
import {attesterPublicKeySamples} from "../../../../api-mocks/apis/attester/attester-endpoints";
import MenuBarScreen from "../../../screenobjects/menu-bar.screen";
import SettingsScreen from "../../../screenobjects/settings.screen";
import ContactScreen from "../../../screenobjects/contacts.screen";
import ContactPublicKeyScreen from "../../../screenobjects/contact-public-key.screen";
import {CommonData} from "../../../data";
import DataHelper from "../../../helpers/DataHelper";


describe('SETUP: ', () => {

  it('app updates older public keys to newer but not vice versa', async () => {

      let firstFetchedDate, secondFetchedDate, thirdFetchedDate, fourthFetchedDate;

      const mockApi = new MockApi();

      mockApi.fesConfig = {
          clientConfiguration: {
              flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
              key_manager_url: "https://ekm.flowcrypt.com",
          }
      };
      mockApi.attesterConfig = {
          servedPubkeys: {
              'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion
          }
      };
    const userEmail = CommonData.updateUser.email;
    const oldSignatureDate = CommonData.updateUser.oldSignatureDate;
    const oldFingerprintsValue = CommonData.updateUser.oldFingerprints;
    const newSignatureDate = CommonData.updateUser.newSignatureDate;
    const newFingerprintsValue = CommonData.updateUser.newFingerprints;

    await mockApi.withMockedApis(async () => {
      //stage 1
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
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
      // Go to Contact screen
      await ContactScreen.clickOnContact(userEmail);
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
      await ContactPublicKeyScreen.clickOnFingerPrint();

      await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
      await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
      await PublicKeyDetailsScreen.checkSignatureDateValue(oldSignatureDate);
      firstFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
      await PublicKeyDetailsScreen.checkFingerPrintsValue(oldFingerprintsValue);

      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuIcon();
      await MenuBarScreen.clickInboxButton();
      //stage 2
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyNewerVersion
        }
      };
      await MailFolderScreen.checkInboxScreen();
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
      // Go to Contact screen
      await ContactScreen.clickOnContact(userEmail);
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
      await ContactPublicKeyScreen.clickOnFingerPrint();

      await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
      await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
      await PublicKeyDetailsScreen.checkSignatureDateValue(newSignatureDate);
      secondFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
      await PublicKeyDetailsScreen.checkFingerPrintsValue(newFingerprintsValue);

      await expect(firstFetchedDate).toBeLessThan(secondFetchedDate);

      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuIcon();
      await MenuBarScreen.clickInboxButton();
      //stage 3
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion
        }
      };
      await MailFolderScreen.checkInboxScreen();
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
      // Go to Contact screen
      await ContactScreen.clickOnContact(userEmail);
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
      await ContactPublicKeyScreen.clickOnFingerPrint();

      await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
      await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
      await PublicKeyDetailsScreen.checkSignatureDateValue(newSignatureDate);
      thirdFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
      await PublicKeyDetailsScreen.checkFingerPrintsValue(newFingerprintsValue);

      await expect(secondFetchedDate).toBeLessThan(thirdFetchedDate);

      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickTrashButton();
      await ContactScreen.checkContactScreen();
      await ContactScreen.checkEmptyList();

      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuIcon();
      await MenuBarScreen.clickInboxButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(userEmail);
      await NewMessageScreen.checkAddedRecipient(userEmail);
      await NewMessageScreen.clickBackButton();

      await MenuBarScreen.clickMenuIcon();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContact(userEmail);
      // Go to Contact screen
      await ContactScreen.clickOnContact(userEmail);
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
      await ContactPublicKeyScreen.clickOnFingerPrint();

      await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
      await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
      await PublicKeyDetailsScreen.checkSignatureDateValue(oldSignatureDate);
      fourthFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
      await PublicKeyDetailsScreen.checkFingerPrintsValue(oldFingerprintsValue);

      await expect(thirdFetchedDate).toBeLessThan(fourthFetchedDate);
    });
  });
});
