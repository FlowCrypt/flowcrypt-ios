import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('check thread rendering', async () => {
    const senderEmail = CommonData.threadMessage.sender;
    const emailSubject = CommonData.threadMessage.subject;
    const firstMessage = CommonData.threadMessage.firstThreadMessage;
    const secondMessage = CommonData.threadMessage.secondThreadMessage;
    const thirdMessage = CommonData.threadMessage.thirdThreadMessage;
    const userEmail = CommonData.account.email;
    const dateFirst = CommonData.threadMessage.firstDate;
    const dateSecond = CommonData.threadMessage.secondDate;
    const dateThird = CommonData.threadMessage.thirdDate;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkThreadMessage(senderEmail, emailSubject, thirdMessage, dateThird, 2);
    await EmailScreen.checkThreadMessage(userEmail, emailSubject, secondMessage, dateSecond, 1);
    await EmailScreen.checkThreadMessage(senderEmail, emailSubject, firstMessage, dateFirst);
  });
});
