import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { CommonData } from 'tests/data';
import { MockApiConfig } from 'api-mocks/mock-config';
import { attesterPublicKeySamples } from 'api-mocks/apis/attester/attester-endpoints';

describe('SETUP: ', () => {

  it('can find email on attester', async () => {
    const mockApi = new MockApi();
    const recipient = 'available.on@attester.test';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient]: attesterPublicKeySamples.valid,
      }
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(recipient);
      await NewMessageScreen.checkAddedRecipientColor(CommonData.validMockUser.name, 0, 'green');
    });
  });
});
