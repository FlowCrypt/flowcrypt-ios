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
  it('check forward', async () => {
    const mockApi = new MockApi();
    const subject = 'email with text attachment';
    const subject2 = 'Test forward message with attached pub key';
    const subject3 = 'Test 1';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject, subject2, subject3],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(subject);

      // check attachment after forward
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await EmailScreen.checkAttachment('test.txt');
      await EmailScreen.clickOnAttachmentCell();
      await EmailScreen.checkAttachmentTextView('email with text attachment');

      await NewMessageScreen.clickBackButton();
      await NewMessageScreen.clickBackButton();
      await EmailScreen.clickBackButton();
      // check forward message with attached pub key
      await MailFolderScreen.clickOnEmailBySubject(subject2);
      await browser.pause(1000);
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await NewMessageScreen.checkSubject(`Fwd: ${subject2}`);

      // Check forward without any added text
      await NewMessageScreen.clickBackButton();
      await EmailScreen.clickBackButton();
      await MailFolderScreen.clickOnEmailBySubject(subject3);
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
      await MailFolderScreen.clickOnEmailBySubject(`Fwd: ${subject3}`);
    });
  });
});
