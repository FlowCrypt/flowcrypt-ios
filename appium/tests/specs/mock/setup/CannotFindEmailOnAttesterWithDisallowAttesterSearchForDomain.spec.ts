import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { CommonData } from 'tests/data';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('SETUP: ', () => {

  it('cannot find email on attester with disallow_attester_search_for_domains=*', async () => {
    const mockApi = new MockApi();

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
        disallow_attester_search_for_domains: ["*"]
      }
    };
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient('available.on@attester.test');
      await NewMessageScreen.checkAddedRecipientColor('available.on@attester.test', 0, 'gray');
    });
  });
});
