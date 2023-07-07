import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  EmailScreen,
  MailFolderScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {
  it('check forward message with attached pub key', async () => {
    const mockApi = new MockApi();
    const subject = 'Test forward message with attached pub key';

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

      await browser.pause(1000);
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await NewMessageScreen.checkSubject(`Fwd: ${subject}`);
    });
  });
});
