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

  it('EKM key update errors handled gracefully', async () => {

    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 2 - EKM down
      mockApi.ekmConfig = {
        returnError: {
          code: 500,
          message: 'Test EKM down'
        }
      }
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 3 - error shown to user
      // mockApi.ekmConfig = {
      //   returnKeys: [ekmKeySamples.key0.prv.substring(0, 300)]
      // }
      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkModalMessage(CommonData.refreshingKeysFromEkm.errorMessage);
      await BaseScreen.clickOkButtonOnError();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);
    });
  });
});
