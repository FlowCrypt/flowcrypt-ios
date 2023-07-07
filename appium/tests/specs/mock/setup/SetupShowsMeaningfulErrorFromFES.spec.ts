import { MockApi } from 'api-mocks/mock';
import { CommonData } from 'tests/data';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { SplashScreen } from '../../../screenobjects/all-screens';
import BaseScreen from '../../../screenobjects/base.screen';

describe('SETUP: ', () => {
  it('setup shows meaningful error when FES returns 400', async () => {
    const mockApi = new MockApi();
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = {
      returnError: {
        code: 400,
        message: 'some client err',
      },
    };
    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await BaseScreen.checkModalMessage(
        'Login Error\n' + 'EnterpriseServerApi 400 message:some client err GET https://127.0.0.1:8001/fes/api/',
      );

      mockApi.fesConfig = {
        returnError: {
          code: 400,
          message: 'some client err',
          format: 'wrong-text',
        },
      };

      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkModalMessage('Startup Error\n"some client err"');

      mockApi.fesConfig = {
        returnError: {
          code: 400,
          message: 'some client err',
          format: 'wrong-json',
        },
      };

      await AppiumHelper.restartApp(processArgs);
      await BaseScreen.checkModalMessage(
        'Startup Error\n' + '{"wrongFieldError":{"wrongFieldCode":400,"wrongFieldMessage":"some client err"}}',
      );
    });
  });
});
