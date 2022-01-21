import { MockApi } from 'api-mocks/mock';
import {
    SplashScreen,
    SetupKeyScreen,
    PublicKeyDetailsScreen,
    ContactPublicKeyScreen,
    MenuBarScreen,
    SettingsScreen,
    ContactScreen,
} from '../../../screenobjects/all-screens';
import {attesterPublicKeySamples} from "../../../../api-mocks/apis/attester/attester-endpoints";
import {CommonData} from "../../../data";
import DataHelper from "../../../helpers/DataHelper";
import PublicKeyHelper from "../../../helpers/PublicKeyHelper";


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

      await PublicKeyHelper.checkSignatureAndFingerprints(userEmail, oldSignatureDate, oldFingerprintsValue);
      firstFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

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
      await PublicKeyHelper.checkSignatureAndFingerprints(userEmail, newSignatureDate, newFingerprintsValue);

      secondFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

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
      await PublicKeyHelper.checkSignatureAndFingerprints(userEmail, newSignatureDate, newFingerprintsValue);

      thirdFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
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

      await PublicKeyHelper.checkSignatureAndFingerprints(userEmail, oldSignatureDate, oldFingerprintsValue);

      fourthFetchedDate = await DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

      await expect(thirdFetchedDate).toBeLessThan(fourthFetchedDate);
    });
  });
});
