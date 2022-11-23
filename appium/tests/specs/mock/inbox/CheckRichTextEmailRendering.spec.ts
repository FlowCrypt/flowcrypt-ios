import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { GoogleMockMessage } from 'api-mocks/apis/google/google-messages';

describe('INBOX: ', () => {

  it('check rich text email rendering', async () => {
    const sender = CommonData.richTextMessage.sender;
    const subject = CommonData.richTextMessage.subject;
    const message = CommonData.richTextMessage.message;
    const attachmentName = CommonData.richTextMessage.attachmentName;
    const attachmentText = CommonData.richTextMessage.attachmentText;

    const messageWithEmptyBodySubject = CommonData.richTextMessageWithEmptyBody.subject;
    const messageWithLargeAttachmentSubject = CommonData.richTextMessageWithLargeAttachment.subject;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject, messageWithEmptyBodySubject, messageWithLargeAttachmentSubject] as GoogleMockMessage[],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkOpenedEmail(sender, subject, message);
      await EmailScreen.checkAttachment(attachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await EmailScreen.checkAttachmentTextView(attachmentText);

      await EmailScreen.clickBackButton();
      await EmailScreen.clickBackButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(messageWithEmptyBodySubject);
      await EmailScreen.checkOpenedEmail(sender, messageWithEmptyBodySubject, '');
      await EmailScreen.checkAttachment(attachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await EmailScreen.checkAttachmentTextView(attachmentText);

      await EmailScreen.clickBackButton();
      await EmailScreen.clickBackButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(messageWithLargeAttachmentSubject);
      await EmailScreen.checkOpenedEmail(sender, messageWithLargeAttachmentSubject, message);
      await EmailScreen.checkAttachment(attachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await EmailScreen.checkAttachmentTextView(attachmentText);
    });
  });
});
