import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  MenuBarScreen
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('check thread rendering', async () => {
    const senderName = CommonData.threadMessage.senderName;
    const emailSubject = CommonData.threadMessage.subject;
    const firstMessage = CommonData.threadMessage.firstThreadMessage;
    const secondMessage = CommonData.threadMessage.secondThreadMessage;
    const thirdMessage = CommonData.threadMessage.thirdThreadMessage;
    const userEmail = CommonData.account.email;
    const dateFirst = CommonData.threadMessage.firstDate;
    const dateSecond = CommonData.threadMessage.secondDate;
    const dateThird = CommonData.threadMessage.thirdDate;
    const archivedThreadSubject = CommonData.archivedThread.subject;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkInboxEmailActions();
    await EmailScreen.checkThreadMessage(senderName, emailSubject, thirdMessage, 2, dateThird);
    await EmailScreen.checkThreadMessage(userEmail, emailSubject, secondMessage, 1, dateSecond);
    await EmailScreen.checkThreadMessage(senderName, emailSubject, firstMessage, 0, dateFirst);
    await EmailScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.clickAllMailButton();
    await MailFolderScreen.clickOnEmailBySubject(archivedThreadSubject);
    await EmailScreen.checkArchivedEmailActions();
  });
});
