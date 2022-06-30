import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  MailFolderScreen,
  SearchScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import AppiumHelper from "../../../helpers/AppiumHelper";
import BaseScreen from 'tests/screenobjects/base.screen';

describe('SETUP: ', () => {

  it('check decrypt message when there are no keys available', async () => {

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
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          messages: ['CC and BCC test'],
        }
      }
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
      await MailFolderScreen.clickSearchButton();
      await SearchScreen.searchAndClickEmailBySubject(CommonData.recipientsListEmail.subject);
      await BaseScreen.checkModalMessage(CommonData.errors.decryptMessageWithNoKeys);

    });
  });
});
