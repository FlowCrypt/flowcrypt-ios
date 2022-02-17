import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('check thread rendering', async () => {

    const senderEmail = CommonData.threadMessage.senderEmail;
    const userEmail = CommonData.account.email;
    const emailSubject = CommonData.threadMessage.subject;
    const firstMessage = CommonData.threadMessage.firstThreadMessage;
    const secondMessage = CommonData.threadMessage.secondTreadMessage;
    const thirdMessage = CommonData.threadMessage.thirdThreadMessage;

    const recipientsButton = CommonData.recipientsListEmail.recipients;
    const toLabel = CommonData.recipientsListEmail.to;
    const ccLabel = CommonData.recipientsListEmail.cc;
    const bccLabel = CommonData.recipientsListEmail.bcc;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);

    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, firstMessage);
    await EmailScreen.checkRecipientsButton(recipientsButton);
    await EmailScreen.clickRecipientsButton();
    await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
  });
});
