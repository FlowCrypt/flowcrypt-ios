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

  it('handle situation when refreshing keys from EKM and have no local keys', async () => {
    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key0.prv]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);

      // stage 2 - erase local keys
      mockApi.ekmConfig = {
        returnKeys: []
      }
      await AppiumHelper.restartApp(processArgs);
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkIfKeysAreEmpty();

      // stage 3 - check situation when there are no local keys but keys are returned from EKM
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.key0.prv]
      }
      await AppiumHelper.restartApp(processArgs);
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0]);
    });
  });
});
