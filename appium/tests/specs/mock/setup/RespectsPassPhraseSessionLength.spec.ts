import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { MockApi } from 'api-mocks/mock';
import { CommonData } from 'tests/data';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import BaseScreen from 'tests/screenobjects/base.screen';
import {
  SplashScreen
} from '../../../screenobjects/all-screens';
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";

describe('SETUP: ', () => {

  it('respects in_memory_pass_phrase_session_length and passphrase expire in that seconds', async () => {

    const mockApi = new MockApi();
    const testMessageSubject = 'Message with cc and multiple recipients and text attachment';
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2e.prv]
    }
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [testMessageSubject],
    });

    await mockApi.withMockedApis(async () => {
      // stage 1: setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // stage 2: check if passphrase doesn't expire (default 4 hours)
      await browser.pause(5000);
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);

      // stage 3: set in_memory_pass_phrase_session_length and check if passphrase expires in 5 seconds
      mockApi.fesConfig = {
        clientConfiguration: {
          flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
          key_manager_url: CommonData.keyManagerURL.mockServer,
          in_memory_pass_phrase_session_length: 5
        }
      };
      await AppiumHelper.restartApp(processArgs);
      await browser.pause(5000);
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
      await BaseScreen.checkModalMessage('Please enter pass phrase');
    });
  });
});
