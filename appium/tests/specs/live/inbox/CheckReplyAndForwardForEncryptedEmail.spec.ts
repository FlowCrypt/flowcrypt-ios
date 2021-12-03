import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to reply or forward email and check info from composed email', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const attachmentName = CommonData.encryptedEmailWithAttachment.attachmentName;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${emailText}`;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.searchEmailBySubject(emailSubject);
    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, replySubject, quoteText);

    await NewMessageScreen.clickBackButton();
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickForwardButton();
    await NewMessageScreen.checkFilledComposeEmailInfo("", forwardSubject, quoteText, attachmentName);
    await NewMessageScreen.deleteAttachment();
  });
});
