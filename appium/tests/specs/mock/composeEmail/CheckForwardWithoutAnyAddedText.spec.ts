import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  EmailScreen,
  MailFolderScreen,
  MenuBarScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {
  it('user is able to foward message without any added text', async () => {
    const mockApi = new MockApi();
    const subject = 'Test 1';

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

      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await NewMessageScreen.setAddRecipient('demo@flowcrypt.com');
      // Check if no error messages are shown when there are no added text
      await NewMessageScreen.clickSendButton();
      await NewMessageScreen.clickSendPlainMessageButton();
      await EmailScreen.clickBackButton();
      // Check if sent email is displayed correctly
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.checkSentScreen();
      await MailFolderScreen.clickOnEmailBySubject(`Fwd: ${subject}`);
    });
  });
});
