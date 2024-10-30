import { MockApi } from 'api-mocks/mock';
import { KeysScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';
import { ekmKeySamples } from '../../../../api-mocks/apis/ekm/ekm-endpoints';
import { CommonData } from '../../../data';
import RefreshKeyScreen from '../../../screenobjects/refresh-key.screen';
import BaseScreen from '../../../screenobjects/base.screen';
import AppiumHelper from '../../../helpers/AppiumHelper';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('SETUP: ', () => {
  it('app auto updates keys from EKM during startup with a pass phrase prompt', async () => {
    const passPhrase = CommonData.account.passPhrase;
    const successMessage = CommonData.refreshingKeysFromEkm.updatedSuccessfully;
    const processArgs = CommonData.mockProcessArgs;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv],
    };

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 2 - prompt appears / wrong pass phrase rejected / cancel
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0.prv, ekmKeySamples.key1.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase('wrong passphrase');
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkModalMessage(CommonData.refreshingKeysFromEkm.wrongPassPhrase);
      await RefreshKeyScreen.clickSystemOkButton();
      await RefreshKeyScreen.fillPassPhrase('wrong passphrase');
      await RefreshKeyScreen.cancelRefresh();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 3 - new key gets added
      await AppiumHelper.restartApp(processArgs);
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.key1]);

      // stage 4 - modified key gets updated
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0Updated.prv, ekmKeySamples.key1.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await RefreshKeyScreen.waitForScreen(true);
      await RefreshKeyScreen.fillPassPhrase(passPhrase);
      await RefreshKeyScreen.clickOkButton();
      await BaseScreen.checkToastMessage(successMessage);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Updated, ekmKeySamples.key1]);

      // stage 5 - older version of key does not get updated
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0.prv, ekmKeySamples.key1.prv],
      };
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0Updated, ekmKeySamples.key1]);
    });
  });
});
