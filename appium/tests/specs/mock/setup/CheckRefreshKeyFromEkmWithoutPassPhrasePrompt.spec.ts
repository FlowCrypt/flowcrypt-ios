import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import BaseScreen from "../../../screenobjects/base.screen";
import AppiumHelper from "../../../helpers/AppiumHelper";

describe('SETUP: ', () => {

  it('app auto updates keys from EKM during startup without pass phrase prompt', async () => {

    const mockApi = MockApi.e2eMock;
    const processArgs = CommonData.mockProcessArgs;

    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 2 - keys get auto-updated
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0.prv, ekmKeySamples.key1.prv]
      }
      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkToastMessage(CommonData.refreshingKeysFromEkm.updatedSuccessfully);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.key1]);

      // stage 3 - nothing to update
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.key1]);
    });
  });
});
