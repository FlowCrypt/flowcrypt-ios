import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';

describe('INBOX: ', () => {

  it('user is able to reply or forward email and check info from composed email', async () => {

    const senderEmail = CommonData.emailWithMultipleRecipientsWithCC.sender;
    const senderName = CommonData.emailWithMultipleRecipientsWithCC.senderName;
    const recipientName = CommonData.emailWithMultipleRecipientsWithCC.recipientName;
    const ccEmail = CommonData.emailWithMultipleRecipientsWithCC.cc;
    const emailSubject = CommonData.emailWithMultipleRecipientsWithCC.subject;
    const emailText = CommonData.emailWithMultipleRecipientsWithCC.message;
    const encryptedAttachmentName = CommonData.emailWithMultipleRecipientsWithCC.encryptedAttachmentName;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${emailText}`;

    await MockApi.e2eMock.withMockedApis(async () => {
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
        cc: [ccEmail]
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
