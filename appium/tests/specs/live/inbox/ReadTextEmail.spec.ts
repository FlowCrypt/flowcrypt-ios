import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('user is able to view text email and recipients list', async () => {

    const senderEmail = CommonData.recipientsListEmail.sender;
    const emailSubject = CommonData.recipientsListEmail.subject;
    const emailText = CommonData.recipientsListEmail.message;
    const recipientsButton = CommonData.recipientsListEmail.recipients;
    const toLabel = CommonData.recipientsListEmail.to;
    const ccLabel = CommonData.recipientsListEmail.cc;
    const bccLabel = CommonData.recipientsListEmail.bcc;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);

    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkRecipientsButton(recipientsButton);
    await EmailScreen.clickRecipientsButton();
    await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
  });
});
