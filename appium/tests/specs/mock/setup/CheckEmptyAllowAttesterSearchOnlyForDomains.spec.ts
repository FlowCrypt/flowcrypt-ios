import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen
} from '../../../screenobjects/all-screens';
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";

describe('SETUP: ', () => {

  it('check if no domains are allowed when allow_attester_search_only_for_domains: [] is set', async () => {

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: "https://ekm.flowcrypt.com",
        allow_attester_search_only_for_domains: [],
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient('empty-setting@enabled.test');
      // Checking added recipients color
      await NewMessageScreen.checkAddedRecipientColor('empty-setting@enabled.test', 0, 'gray');
    });
  });
});
