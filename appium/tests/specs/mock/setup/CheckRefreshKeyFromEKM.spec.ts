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
import RefreshKeyScreen from "../../../screenobjects/refresh-key.screen";
import BaseScreen from "../../../screenobjects/base.screen";
import AppiumHelper from "../../../helpers/AppiumHelper";

const ekmMockServer = 'http://127.0.0.1:8001/ekm';
const successMessage = CommonData.refreshKeys.updatedSuccessfully;

const goToKeysScreen = async () => {
  await MenuBarScreen.clickMenuIcon();
  await MenuBarScreen.clickSettingsButton();
  await SettingsScreen.clickOnSettingItem('Keys');
}

const logoutUserFromKeyScreen = async () => {
  await KeysScreen.clickBackButton();
  await MenuBarScreen.clickMenuIcon();
  await MenuBarScreen.clickLogout();
  await SplashScreen.checkLoginPage();
}

describe('SETUP: ', () => {

  it('app auto updates keys from EKM during startup with a pass phrase prompt', async () => {

    const wrongPassPhraseError = CommonData.refreshKeys.wrongPassPhrase;
    const passPhrase = CommonData.account.passPhrase;

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: ekmMockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ ekmPrivateKeySamples.key0.prv ]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 2 - prompt appears / wrong pass phrase rejected / cancel
      mockApi.ekmConfig = {
        returnKeys: [ ekmPrivateKeySamples.key0.prv, ekmPrivateKeySamples.key1.prv ]
      }
      await AppiumHelper.restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase('wrong passphrase');
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkModalMessage(wrongPassPhraseError);
      await RefreshKeyScreen.clickOkButton();
      await RefreshKeyScreen.cancelRefresh();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 3 - new key gets added
      await AppiumHelper.restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);

      // stage 4 - modified key gets updated, removed key does not get removed
      mockApi.ekmConfig = {
        returnKeys: [ ekmPrivateKeySamples.key0Updated.prv ]
      }
      await AppiumHelper.restartApp();
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0Updated, ekmPrivateKeySamples.key1]);

      // stage 5 - older version of key does not get updated
      mockApi.ekmConfig = {
        returnKeys: [ ekmPrivateKeySamples.key0.prv ]
      }
      await AppiumHelper.restartApp();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0Updated, ekmPrivateKeySamples.key1]);
      await logoutUserFromKeyScreen();
    });
  });

  it('app auto updates keys from EKM during startup without pass phrase prompt', async () => {

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN"],
        key_manager_url: ekmMockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ ekmPrivateKeySamples.key0.prv ]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 2 - keys get auto-updated
      mockApi.ekmConfig = {
        returnKeys: [ ekmPrivateKeySamples.key0.prv, ekmPrivateKeySamples.key1.prv ]
      }
      await AppiumHelper.restartApp();
      await BaseScreen.checkToastMessage(successMessage);
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);

      // stage 3 - nothing to update
      await AppiumHelper.restartApp();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0, ekmPrivateKeySamples.key1]);
      await logoutUserFromKeyScreen();
    });
  });

  it('EKM key update errors handled gracefully', async () => {

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN"],
        key_manager_url: ekmMockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ ekmPrivateKeySamples.key0.prv ]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 2 - EKM down
      mockApi.ekmConfig = {
        returnError: {
          code: 500,
          message: 'Test EKM down'
        }
      }
      await AppiumHelper.restartApp();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);

      // stage 3 - error shown to user

      mockApi.ekmConfig = {
        returnKeys: [ ekmPrivateKeySamples.key0.prv.substring(0, 300) ]
      }
      await AppiumHelper.restartApp();
      await goToKeysScreen();
      await KeysScreen.checkKeysScreen([ekmPrivateKeySamples.key0]);
    });
  });
});
