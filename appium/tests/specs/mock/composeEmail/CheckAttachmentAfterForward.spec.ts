import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  EmailScreen,
  MailFolderScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check attachment after forward', async () => {
    const mockApi = new MockApi();
    const subject = 'Test attachment after forward';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(subject);

      // check recipient text field focus for forward message
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await EmailScreen.checkAttachment('test.txt');
      await EmailScreen.clickOnAttachmentCell();
      await EmailScreen.checkAttachmentTextView('Test attachment after forward');
    });
  });
});
