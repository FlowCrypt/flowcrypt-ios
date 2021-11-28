import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to view key mismatch email', async () => {

    const senderEmail = CommonData.account.email;
    const emailSubject = CommonData.keyMismatchEmail.subject;
    const emailText = CommonData.keyMismatchEmail.message;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
