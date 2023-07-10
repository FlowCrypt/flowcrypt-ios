import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { MockApi } from 'api-mocks/mock';
import { CommonData } from 'tests/data';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import BaseScreen from 'tests/screenobjects/base.screen';
import { KeysScreen, SplashScreen } from '../../../screenobjects/all-screens';
import SetupKeyScreen from '../../../screenobjects/setup-key.screen';

describe('SETUP: ', () => {
  it("will not update a revoked private key with valid one and delete local key if it's removed from EKM and not revoked one", async () => {
    const processArgs = CommonData.mockProcessArgs;
    const successMessage = CommonData.refreshingKeysFromEkm.updatedSuccessfully;

    const mockApi = new MockApi();

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ['NO_PRV_CREATE', 'NO_PRV_BACKUP', 'NO_ATTESTER_SUBMIT', 'PRV_AUTOIMPORT_OR_AUTOGEN'],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      },
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0Revoked.prv],
    };

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Revoked]);

      // stage 2 - updated key (with same fingerprint as revoked key) doesn't get updated
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0Updated.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Revoked]);

      // stage 3 - another key (with different fingerprint compared to the revoked key) gets added
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0Revoked.prv, ekmKeySamples.key1.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkToastMessage(successMessage);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Revoked, ekmKeySamples.key1]);

      // stage 4 - now key0Revoked and key1 key is saved in local
      // Check if revoked key doesn't get removed if EKM doesn't return revoked key
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key1.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Revoked, ekmKeySamples.key1]);

      // stage 5 check key gets removed successfully when EKM doesn't return valid key(key1 in this case)
      mockApi.ekmConfig = {
        returnKeys: [],
      };
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Revoked]);
    });
  });
});
