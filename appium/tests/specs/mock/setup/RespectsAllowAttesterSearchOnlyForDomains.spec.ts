import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { attesterPublicKeySamples } from "../../../../api-mocks/apis/attester/attester-endpoints";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { CommonData } from 'tests/data';
import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';

describe('SETUP: ', () => {

  it('respects allow_attester_search_only_for_domains and ignore disallow_attester_search_for_domains if it\'s present', async () => {

    const mockApi = new MockApi();
    const enabledEmail = 'attester@enabled.test';
    const disabledEmail = 'attester@disabled.test';
    const enabledUserName = CommonData.validMockUser.name;
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
        allow_attester_search_only_for_domains: ["enabled.test"],
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [enabledEmail]: attesterPublicKeySamples.valid,
        [disabledEmail]: attesterPublicKeySamples.valid
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2e.prv]
    }

    await mockApi.withMockedApis(async () => {
      // stage 1: setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      // stage 2: check if allow_attester_search_only_for_domains is respected
      await NewMessageScreen.setAddRecipient(disabledEmail);
      await NewMessageScreen.setAddRecipient(enabledEmail);
      // Checking added recipients color
      await NewMessageScreen.checkAddedRecipientColor(disabledEmail, 0, 'gray');
      await NewMessageScreen.checkAddedRecipientColor(enabledUserName, 1, 'green');

      // stage 3: check if disallow_attester_search_for_domains not respected when allow_attester_search_only_for_domains is set
      mockApi.fesConfig = {
        clientConfiguration: {
          flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
          key_manager_url: CommonData.keyManagerURL.mockServer,
          allow_attester_search_only_for_domains: ["enabled.test"],
          disallow_attester_search_for_domains: ["*"]
        }
      };
      await AppiumHelper.restartApp(processArgs);
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(disabledEmail);
      await NewMessageScreen.setAddRecipient(enabledEmail);
      // Checking added recipients color
      await NewMessageScreen.checkAddedRecipientColor(disabledEmail, 0, 'gray');
      await NewMessageScreen.checkAddedRecipientColor(enabledUserName, 1, 'green');
    });
  });
});
