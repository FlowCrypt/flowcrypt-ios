import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('user is able to see plain email without setting pass phrase after restart app', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    await driver.terminateApp(CommonData.bundleId.id);
    await driver.activateApp(CommonData.bundleId.id);

    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(emailSubject);

    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
