import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';

describe('INBOX: ', () => {

  it('user is able to see plain email without setting pass phrase after restart app', async () => {

    const processArgs = CommonData.mockProcessArgs;
    const senderName = CommonData.sender.name;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
    });
  });
});
