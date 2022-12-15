import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  PublicKeyScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import AppiumHelper from "../../../helpers/AppiumHelper";
import { MockApiConfig } from 'api-mocks/mock-config';

describe('SETUP: ', () => {

  it('respects hide_armor_meta if it\'s present', async () => {
    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv]
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();

      // check if public key contains armor meta
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);
      await KeysScreen.clickOnKey();
      await KeysScreen.checkSelectedKeyScreen();
      await KeysScreen.clickOnShowPublicKey();
      await PublicKeyScreen.checkPublicKeyContains('Version: ');
      await PublicKeyScreen.checkPublicKeyContains('Comment: ');

      // add HIDE_ARMOR_META config
      mockApi.fesConfig = {
        clientConfiguration: {
          flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE", "HIDE_ARMOR_META"],
          key_manager_url: CommonData.keyManagerURL.mockServer,
        }
      };
      await AppiumHelper.restartApp(processArgs);

      // check if public key doesn't show armor meta
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);
      await KeysScreen.clickOnKey();
      await KeysScreen.checkSelectedKeyScreen();
      await KeysScreen.clickOnShowPublicKey();
      await PublicKeyScreen.checkPublicKeyNotContains('Version: ');
      await PublicKeyScreen.checkPublicKeyNotContains('Comment: ');
    });
  });
});
