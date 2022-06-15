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
import { attesterPublicKeySamples } from "../../../../api-mocks/apis/attester/attester-endpoints";
import { CommonData } from "../../../data";
import DataHelper from "../../../helpers/DataHelper";
import PublicKeyHelper from "../../../helpers/PublicKeyHelper";
import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';


describe('SETUP: ', () => {

  it('app updates older public keys to newer but not vice versa', async () => {

    let firstFetchedDate, secondFetchedDate, thirdFetchedDate, fourthFetchedDate;

    const mockApi = new MockApi();

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eValidKey.prv]
    }
    const userEmail = CommonData.updateRecipientPublicKey.email;
    const userName = CommonData.updateRecipientPublicKey.name;
    const oldSignatureDate = CommonData.updateRecipientPublicKey.oldSignatureDate;
    const oldFingerprintsValue = CommonData.updateRecipientPublicKey.oldFingerprints;
    const newSignatureDate = CommonData.updateRecipientPublicKey.newSignatureDate;
    const newFingerprintsValue = CommonData.updateRecipientPublicKey.newFingerprints;

    await mockApi.withMockedApis(async () => {
      //stage 1
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();

      await PublicKeyHelper.loadRecipientInComposeThenCheckSignatureAndFingerprints(
        userEmail,
        oldSignatureDate,
        oldFingerprintsValue,
        userName
      );
      firstFetchedDate = DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      //stage 2
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyNewerVersion
        }
      };
      await PublicKeyHelper.loadRecipientInComposeThenCheckSignatureAndFingerprints(
        userEmail,
        newSignatureDate,
        newFingerprintsValue,
        userName
      );

      secondFetchedDate = DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

      expect(firstFetchedDate).toBeLessThan(secondFetchedDate);

      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      //stage 3
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion
        }
      };
      await PublicKeyHelper.loadRecipientInComposeThenCheckSignatureAndFingerprints(
        userEmail,
        newSignatureDate,
        newFingerprintsValue,
        userName
      );

      thirdFetchedDate = DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());
      expect(secondFetchedDate).toBeLessThan(thirdFetchedDate);
      //stage 4
      await PublicKeyDetailsScreen.clickBackButton();
      await ContactPublicKeyScreen.checkPgpUserId(userEmail);
      await ContactPublicKeyScreen.clickTrashButton();
      await ContactScreen.checkContactScreen();
      await ContactScreen.checkEmptyList();

      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();

      await PublicKeyHelper.loadRecipientInComposeThenCheckSignatureAndFingerprints(
        userEmail,
        oldSignatureDate,
        oldFingerprintsValue,
        userName
      );

      fourthFetchedDate = DataHelper.convertDateToMSec(await PublicKeyDetailsScreen.getLastFetchedDateValue());

      expect(thirdFetchedDate).toBeLessThan(fourthFetchedDate);
    });
  });
});
