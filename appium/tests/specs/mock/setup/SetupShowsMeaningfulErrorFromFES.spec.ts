import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import BaseScreen from "../../../screenobjects/base.screen";


describe('SETUP: ', () => {

  it('setup shows meaningful error when FES returns 400', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = {
      returnError: {
        code: 400,
        message: "some client err"
      }
    };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      await BaseScreen.checkErrorModalForFES('EnterpriseServerApi 400 message:some client err get http://127.0.0.1:8001/fes/api/');
    });
  });
});
