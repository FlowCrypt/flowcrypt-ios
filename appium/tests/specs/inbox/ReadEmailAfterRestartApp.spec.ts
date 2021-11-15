import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to see plain email without setting pass phrase after restart app', async () => {

      const senderEmail = CommonData.sender.email;
      const emailSubject = CommonData.simpleEmail.subject;
      const emailText = CommonData.simpleEmail.message;

      await SplashScreen.login();
      await CreateKeyScreen.setPassPhrase();

      await InboxScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

      await driver.terminateApp(CommonData.bundleId.id);
      await driver.activateApp(CommonData.bundleId.id);

      await InboxScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
