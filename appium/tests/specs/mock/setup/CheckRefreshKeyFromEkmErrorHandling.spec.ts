import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import AppiumHelper from "../../../helpers/AppiumHelper";
import { MockApiConfig } from 'api-mocks/mock-config';

describe('SETUP: ', () => {

  it('EKM server error handled gracefully', async () => {
    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;

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
