import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app and text autoscroll', async () => {

    const recipientEmail = CommonData.contact.email;
    const ccRecipientEmail = CommonData.secondContact.email;
    const bccRecipientEmail = CommonData.recipient.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const longEmailText = CommonData.longEmail.message;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setComposeSecurityMessage(longEmailText);
    await NewMessageScreen.checkRecipientsTextFieldIsInvisible();

    await NewMessageScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText, ccRecipientEmail, bccRecipientEmail);
    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [recipientEmail],
      subject: emailSubject,
      message: emailText,
      cc: [ccRecipientEmail],
      bcc: [bccRecipientEmail]
    });

    await driver.background(3);

    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [recipientEmail],
      subject: emailSubject,
      message: emailText
    });
  });
});
