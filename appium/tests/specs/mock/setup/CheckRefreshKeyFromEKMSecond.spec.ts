import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  MenuBarScreen,
  SettingsScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmPrivateKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import BaseScreen from "../../../screenobjects/base.screen";
import AppiumHelper from "../../../helpers/AppiumHelper";

const goToKeysScreen = async () => {
  await MenuBarScreen.clickMenuIcon();
  await MenuBarScreen.clickSettingsButton();
  await SettingsScreen.clickOnSettingItem('Keys');
}

describe('SETUP: ', () => {

  it('app auto updates keys from EKM during startup without pass phrase prompt', async () => {

    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN"],
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
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 2 - keys get auto-updated
      mockApi.ekmConfig = {
        returnKeys: [ekmPrivateKeySamples.key0.prv, ekmPrivateKeySamples.key1.prv]
      }
      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkToastMessage(CommonData.refreshingKeysFromEkm.updatedSuccessfully);
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);

      // stage 3 - nothing to update
      await AppiumHelper.restartApp(processArgs);
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);
    });
  });
});
