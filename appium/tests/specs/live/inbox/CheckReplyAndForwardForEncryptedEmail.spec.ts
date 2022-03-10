import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('user is able to reply or forward email and check info from composed email', async () => {

    const senderEmail = CommonData.emailWithMultipleRecipientsWithCC.sender;
    const recipientEmail = CommonData.emailWithMultipleRecipientsWithCC.recipient;
    const ccEmail = CommonData.emailWithMultipleRecipientsWithCC.cc;
    const emailSubject = CommonData.emailWithMultipleRecipientsWithCC.subject;
    const emailText = CommonData.emailWithMultipleRecipientsWithCC.message;
    const encryptedAttachmentName = CommonData.emailWithMultipleRecipientsWithCC.encryptedAttachmentName;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${emailText}`;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    // check reply message
    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([senderEmail], replySubject, quoteText);
    await NewMessageScreen.clickBackButton();

    // check reply all message
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickReplyAllButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([recipientEmail, senderEmail], replySubject, quoteText, undefined, [ccEmail]);
    await NewMessageScreen.clickBackButton();

    // check forwarded message
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickForwardButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([], forwardSubject, quoteText, encryptedAttachmentName);
    await NewMessageScreen.deleteAttachment();
  });
});
