import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { attesterPublicKeySamples } from '../../../../api-mocks/apis/attester/attester-endpoints';
import { CommonData } from '../../../data';
import PublicKeyHelper from '../../../helpers/PublicKeyHelper';
import { SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('SETUP: ', () => {
  it('app updates older public keys to newer but not vice versa', async () => {
    let firstFetchedDate, secondFetchedDate, thirdFetchedDate, fourthFetchedDate;

    const userEmail = CommonData.updateRecipientPublicKey.email;
    const userName = CommonData.updateRecipientPublicKey.name;
    const oldSignatureDate = CommonData.updateRecipientPublicKey.oldSignatureDate;
    const oldFingerprintsValue = CommonData.updateRecipientPublicKey.oldFingerprints;
    const newSignatureDate = CommonData.updateRecipientPublicKey.newSignatureDate;
    const newFingerprintsValue = CommonData.updateRecipientPublicKey.newFingerprints;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion,
      },
    };

    await mockApi.withMockedApis(async () => {
      //stage 1
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();

      firstFetchedDate = await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(userEmail, true, {
        signatureDate: oldSignatureDate,
        fingerprintsValue: oldFingerprintsValue,
        recipientName: userName,
      });
      //stage 2
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyNewerVersion,
        },
      };
      secondFetchedDate = await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(userEmail, true, {
        signatureDate: newSignatureDate,
        fingerprintsValue: newFingerprintsValue,
        recipientName: userName,
      });
      expect(firstFetchedDate).toBeLessThan(secondFetchedDate);
      //stage 3
      mockApi.attesterConfig = {
        servedPubkeys: {
          'updating.key@example.test': attesterPublicKeySamples.keyOlderVersion,
        },
      };
      thirdFetchedDate = await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(userEmail, true, {
        signatureDate: newSignatureDate,
        fingerprintsValue: newFingerprintsValue,
        recipientName: userName,
        shouldDeleteKey: true,
      });
      expect(secondFetchedDate).toBeLessThan(thirdFetchedDate);
      //stage 4
      fourthFetchedDate = await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(userEmail, false, {
        signatureDate: oldSignatureDate,
        fingerprintsValue: oldFingerprintsValue,
        recipientName: userName,
      });
      expect(thirdFetchedDate).toBeLessThan(fourthFetchedDate);
    });
  });
});
