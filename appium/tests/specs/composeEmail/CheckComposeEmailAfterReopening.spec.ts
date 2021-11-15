import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app', async () => {

    const recipientEmail = CommonData.contact.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    await SplashScreen.login();
    await CreateKeyScreen.setPassPhrase();

    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(recipientEmail, emailSubject, emailText);

    await driver.background(3);

    await NewMessageScreen.checkFilledComposeEmailInfo(recipientEmail, emailSubject, emailText);
  });
});
