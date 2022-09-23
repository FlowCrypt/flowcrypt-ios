import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('INBOX: ', () => {

  it('user is able to reply or forward email and check info from composed email', async () => {

    const senderEmail = CommonData.encryptedEmailWithAttachment.sender;
    const senderName = CommonData.encryptedEmailWithAttachment.senderName;
    const recipientName = CommonData.encryptedEmailWithAttachment.recipientName;
    const ccName = CommonData.encryptedEmailWithAttachment.cc;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const encryptedAttachmentName = CommonData.encryptedEmailWithAttachment.encryptedAttachmentName;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `${senderName} <${senderEmail}> wrote:\n > ${emailText}`;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Message with cc and multiple recipients and text attachment'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.flowcryptCompatibility.email]: MockUserList.flowcryptCompatibility.pub!,
        [MockUserList.demo.email]: MockUserList.demo.pub!,
        [MockUserList.dmitry.email]: MockUserList.dmitry.pub!,
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

      // check reply message
      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkRecipientsTextFieldIsInvisible();
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [senderName],
        subject: replySubject,
        message: quoteText
      });
      await NewMessageScreen.clickBackButton();

      // check reply all message
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickReplyAllButton();
      await NewMessageScreen.checkRecipientsTextFieldIsInvisible();
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipientName, senderName],
        subject: replySubject,
        message: quoteText,
        cc: [ccName]
      });
      await NewMessageScreen.clickBackButton();

      // check forwarded message
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [],
        subject: forwardSubject,
        message: quoteText,
        attachmentName: encryptedAttachmentName
      });
      await NewMessageScreen.deleteAttachment();
    });
  });
});
