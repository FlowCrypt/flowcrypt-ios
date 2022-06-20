import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app and text autoscroll', async () => {

    const recipientEmail = CommonData.contact.email;
    const recipientName = CommonData.contact.name;
    const ccRecipientEmail = CommonData.secondContact.email;
    const ccRecipientName = CommonData.secondContact.name;
    const bccRecipientEmail = CommonData.recipient.email;
    const bccRecipientName = CommonData.recipient.name;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const longEmailText = CommonData.longEmail.message;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
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
        recipients: [recipientName],
        subject: emailSubject,
        message: emailText,
        cc: [ccRecipientName],
        bcc: [bccRecipientName]
      });

      await driver.background(3);

      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipientName],
        subject: emailSubject,
        message: emailText,
        cc: [ccRecipientName],
        bcc: [bccRecipientName]
      });
    });
  });
});
