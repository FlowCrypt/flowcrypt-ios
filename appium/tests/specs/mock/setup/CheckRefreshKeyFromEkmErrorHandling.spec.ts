import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import AppiumHelper from "../../../helpers/AppiumHelper";

describe('SETUP: ', () => {

  it('EKM server error handled gracefully', async () => {

    const mockApi = MockApi.e2eMock;
    const processArgs = CommonData.mockProcessArgs;

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.e2e, ekmKeySamples.key1]);

      // stage 2 - EKM down
      mockApi.ekmConfig = {
        returnError: {
          code: 500,
          message: 'Test EKM down'
        }
      }
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.e2e, ekmKeySamples.key1]);
    });
  });
});
