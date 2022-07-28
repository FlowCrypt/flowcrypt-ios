import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {

  it('check "archive thread" too aggressive', async () => {
    const mockApi = new MockApi();

    const testMessage = 'Test "archive thread" too aggressive';
    const addedMessageSubject = 'Test "archive thread" too aggressive new message';
    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [testMessage],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.e2e.email]: MockUserList.e2e.pub!
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(testMessage);
      await EmailScreen.clickArchiveButton();

      // Archived thread doesn't appear
      await MailFolderScreen.checkEmailIsNotDisplayed(testMessage);

      // Add message to archived thread (which simulates new incoming message from same sender)
      mockApi.addGoogleMessage('e2e.enterprise.test@flowcrypt.com', addedMessageSubject);
      await MailFolderScreen.refreshMailList();
      // When new message is arrived thread should be displayed      
      await MailFolderScreen.clickOnEmailBySubject(testMessage);
    });
  });
});
