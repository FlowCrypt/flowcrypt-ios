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
    // const remoteContentBlockedMessage = '[remote content blocked for your privacy]';
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
      await EmailScreen.checkOpenedEmail(sender, subject, message);

      // TODO: Check if WKWebView content contains remote content blocked image content. Couldn't seem to find a way to check WKWebView content
      // https://discuss.appium.io/t/appium-and-wkwebview/4769/10
      // await EmailScreen.checkEmailText(remoteContentBlockedMessage);
      // await EmailScreen.checkEmailText('[img]');
    });
  });
});
