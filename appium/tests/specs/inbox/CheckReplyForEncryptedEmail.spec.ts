import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  EmailScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

  it('user is able to reply email and check info from reply email', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmail.subject;
    const emailText = CommonData.encryptedEmail.message;

    const replySubject = `Re: ${emailSubject}`;
    const replyText = `On 10/26/21 at 2:43 PM ${senderEmail} wrote:\n > ${emailText}`;

    await SplashScreen.login();
    await CreateKeyScreen.setPassPhrase();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    await EmailScreen.clickReplyButton();
    await NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, replySubject, replyText);
  });
});
