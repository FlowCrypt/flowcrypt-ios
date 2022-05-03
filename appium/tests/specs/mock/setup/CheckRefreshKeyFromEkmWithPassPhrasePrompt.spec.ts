import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  SettingsScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmPrivateKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import RefreshKeyScreen from "../../../screenobjects/refresh-key.screen";
import BaseScreen from "../../../screenobjects/base.screen";
// import AppiumHelper from "../../../helpers/AppiumHelper";
import experimentalScreen from 'tests/screenobjects/experimental.screen';

const restartApp = async () => {
  await KeysScreen.clickBackButton();
  await SettingsScreen.clickOnSettingItem('Experimental');
  await experimentalScreen.clickReloadAppButton();
}

describe('SETUP: ', () => {

  it('app auto updates keys from EKM during startup with a pass phrase prompt', async () => {

    const passPhrase = CommonData.account.passPhrase;
    const successMessage = CommonData.refreshingKeysFromEkm.updatedSuccessfully;
    // const processArgs = CommonData.mockProcessArgs;

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmPrivateKeySamples.key0.prv]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 2 - prompt appears / wrong pass phrase rejected / cancel
      mockApi.ekmConfig = {
        returnKeys: [ekmPrivateKeySamples.key0.prv, ekmPrivateKeySamples.key1.prv]
      }
      await restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase('wrong passphrase');
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkModalMessage(CommonData.refreshingKeysFromEkm.wrongPassPhrase);
      await RefreshKeyScreen.clickOkButton();
      await RefreshKeyScreen.cancelRefresh();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 3 - new key gets added
      await restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);

      // stage 4 - modified key gets updated, removed key does not get removed
      mockApi.ekmConfig = {
        returnKeys: [ekmPrivateKeySamples.key0Updated.prv]
      }
      await restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0Updated, ekmPrivateKeySamples.key1]);

      // stage 5 - older version of key does not get updated
      mockApi.ekmConfig = {
        returnKeys: [ekmPrivateKeySamples.key0.prv]
      }
      await restartApp();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0Updated, ekmPrivateKeySamples.key1]);
    });
  });
});
