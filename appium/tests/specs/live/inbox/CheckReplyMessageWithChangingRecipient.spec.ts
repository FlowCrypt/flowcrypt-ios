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
    const recipientOfOriginalMessage = CommonData.emailForReplyWithChangingRecipient.recipientName;
    const emailSubject = CommonData.emailForReplyWithChangingRecipient.subject;
    const secondMessage = CommonData.emailForReplyWithChangingRecipient.secondMessage;
    const newRecipientEmail = CommonData.emailForReplyWithChangingRecipient.newRecipientEmail;
    const newRecipientName = CommonData.emailForReplyWithChangingRecipient.newRecipientName;
    const firstRecipientName = CommonData.emailForReplyWithChangingRecipient.firstRecipientName;
    const secondRecipientName = CommonData.emailForReplyWithChangingRecipient.secondRecipientName;
    const thirdRecipientName = CommonData.emailForReplyWithChangingRecipient.thirdRecipientName;


    const replySubject = `Re: ${emailSubject}`;
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
      recipients: [recipientOfOriginalMessage], //TODO This is a bug that needs to be fixed. The reply should still be to original recipients
      subject: replySubject,
      message: quoteText
    });
    await NewMessageScreen.deleteAddedRecipientWithDoubleBackspace();
    await NewMessageScreen.setAddRecipient(newRecipientEmail);

    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [newRecipientName],
      subject: replySubject,
      message: quoteText
    });

    await NewMessageScreen.clickBackButton();
    await EmailScreen.checkThreadMessage(senderEmail, emailSubject, secondMessage, 1);
    await EmailScreen.clickMenuButton();
    await EmailScreen.clickReplyAllButton();

    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [firstRecipientName, secondRecipientName],
      cc: [thirdRecipientName],
      subject: replySubject,
      message: quoteText
    });

    await NewMessageScreen.deleteAddedRecipientWithDoubleBackspace();
    await NewMessageScreen.setAddRecipientByName('Ioan', newRecipientEmail);
    await NewMessageScreen.checkFilledComposeEmailInfo({      //TODO need to fix this, app crashes after adding new recipients
      recipients: [firstRecipientName, newRecipientName],
      cc: [thirdRecipientName],
      subject: replySubject,
      message: quoteText
    });
  });
});
