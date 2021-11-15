import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to view text email', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    await SplashScreen.login();
    await CreateKeyScreen.setPassPhrase();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
