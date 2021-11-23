import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  EmailScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to reply or forward email and check info from composed email', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmail.subject;
    const emailText = CommonData.encryptedEmail.message;

    const replySubject = `Re: ${emailSubject}`;
    const forwardSubject = `Fwd: ${emailSubject}`;
    const quoteText = `On 10/26/21 at 2:43 PM ${senderEmail} wrote:\n > ${emailText}`;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await InboxScreen.checkInboxScreen();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, replySubject, quoteText);
    
    await NewMessageScreen.clickBackButton();
    await EmailScreen.clickForwardButton();
    await NewMessageScreen.checkFilledComposeEmailInfo("", forwardSubject, quoteText);
  });
});
