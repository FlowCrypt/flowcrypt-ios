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

    const senderEmail = CommonData.emailWithMultipleRecipients.sender;
    const senderName = CommonData.emailWithMultipleRecipients.senderName;
    const recipientEmail = CommonData.emailWithMultipleRecipients.recipient;
    const emailSubject = CommonData.emailWithMultipleRecipients.subject;
    const emailText = CommonData.emailWithMultipleRecipients.message;
    const encryptedAttachmentName = CommonData.emailWithMultipleRecipients.encryptedAttachmentName;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${emailText}`;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

    // check reply message
    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([senderName], replySubject, quoteText);
    await NewMessageScreen.clickBackButton();

    // check reply all message
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickReplyAllButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([recipientEmail, senderName], replySubject, quoteText);
    await NewMessageScreen.clickBackButton();

    // check forwarded message
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickForwardButton();
    await NewMessageScreen.checkFilledComposeEmailInfo([], forwardSubject, quoteText, encryptedAttachmentName);
    await NewMessageScreen.deleteAttachment();
  });
});
