import { MockApi } from 'api-mocks/mock';
import {
    SplashScreen,
} from '../../../screenobjects/all-screens';
import {attesterPublicKeySamples} from "../../../../api-mocks/apis/attester/attester-endpoints";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";

describe('SETUP: ', () => {

  it('respects disallow_attester_search_for_domains on a per-domain basis', async () => {

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: "https://ekm.flowcrypt.com",
        disallow_attester_search_for_domains: ["disabled.test"]
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
       'attester@disabled.test': attesterPublicKeySamples.valid,
       'attester@enabled.test': attesterPublicKeySamples.valid
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      // Adding recipients
      await NewMessageScreen.setAddRecipient('attester@disabled.test');
      await NewMessageScreen.setAddRecipient('attester@enabled.test');

      // Checking added recipients color
      await NewMessageScreen.checkAddedRecipientColor('attester@disabled.test', 0, 'gray');
      await NewMessageScreen.checkAddedRecipientColor('attester@enabled.test', 1, 'green');
    });
  });
});
