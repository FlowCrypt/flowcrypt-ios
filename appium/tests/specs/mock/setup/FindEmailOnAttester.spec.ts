import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { attesterPublicKeySamples } from "../../../../api-mocks/apis/attester/attester-endpoints";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { CommonData } from 'tests/data';

describe('SETUP: ', () => {

  it('can find email on attester', async () => {
    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        'available.on@attester.test': attesterPublicKeySamples.valid
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eValidKey.prv]
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient('available.on@attester.test');
      await NewMessageScreen.checkAddedRecipientColor(CommonData.validMockUser.name, 0, 'green');
    });
  });
});
