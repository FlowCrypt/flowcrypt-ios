import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('SETUP: ', () => {

  it('can find email on wkd', async () => {
    const mockApi = new MockApi();
    const recipient = MockUserList.dmitry.email;
    const recipientPrefix = recipient.split('@')[0];

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.wkdConfig = {
      servedPubkeys: {
        [recipientPrefix]: MockUserList.dmitry.pub!,
      }
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(recipient);
      await NewMessageScreen.checkAddedRecipientColor(MockUserList.dmitry.name, 0, 'green');
    });
  });
});
