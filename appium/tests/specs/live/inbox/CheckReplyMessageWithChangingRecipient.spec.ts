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

  it('test for replying to my own email and changing recipient', async () => {

    const senderEmail = CommonData.emailForReplyWithChangingRecipient.senderEmail;
    const oldRecipientName = CommonData.emailForReplyWithChangingRecipient.recipientName;
    const emailSubject = CommonData.emailForReplyWithChangingRecipient.subject;
    const secondMessage = CommonData.emailForReplyWithChangingRecipient.secondMessage;
    const newRecipientEmail = CommonData.emailForReplyWithChangingRecipient.newRecipientEmail;
    const newRecipientName = CommonData.emailForReplyWithChangingRecipient.newRecipientName;

    const replySubject = `Re: Re: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${secondMessage}`;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.checkThreadMessage(senderEmail, emailSubject, secondMessage, 1);

    // check reply message
    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [oldRecipientName],
      subject: replySubject,
      message: quoteText
    });
    await NewMessageScreen.deleteAddedRecipientUsingBackSpaces();
    await NewMessageScreen.setAddRecipientByName(newRecipientName, newRecipientEmail);

    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [newRecipientName],
      subject: replySubject,
      message: quoteText
    });
  });
});
