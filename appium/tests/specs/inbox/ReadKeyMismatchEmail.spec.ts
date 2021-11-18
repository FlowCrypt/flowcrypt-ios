import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
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

    await InboxScreen.clickOnEmailBySubject(emailSubject);

    await EmailScreen.clickOpenAnyway();
    await EmailScreen.checkEmailAddress(senderEmail);
    await EmailScreen.checkEmailSubject(emailSubject);
    await EmailScreen.checkEmailText(emailText);
  });
});
