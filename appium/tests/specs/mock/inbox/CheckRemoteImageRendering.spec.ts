import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { GoogleMockMessage } from 'api-mocks/apis/google/google-messages';

describe('INBOX: ', () => {
  it('check remote image rendering', async () => {
    const sender = CommonData.remoteImageRendering.sender;
    const subject = CommonData.remoteImageRendering.subject;
    const message = CommonData.remoteImageRendering.message;
    const remoteContentBlockedMessage = '[remote content blocked for your privacy]';
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject] as GoogleMockMessage[],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkOpenedEmail(sender, subject, message, true);

      await EmailScreen.checkEmailText(remoteContentBlockedMessage, 0, true);
      await EmailScreen.checkEmailText('[img]', 0, true);
    });
  });
});
