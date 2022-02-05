import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app and text autoscroll', async () => {

    const recipientEmail = CommonData.contact.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const longEmailText = CommonData.longEmail.message;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setComposeSecurityMessage(longEmailText);
    await NewMessageScreen.checkRecipientsTextFieldIsInvisible();

    await NewMessageScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo([recipientEmail], emailSubject, emailText);

    await driver.background(3);

    await NewMessageScreen.checkFilledComposeEmailInfo([recipientEmail], emailSubject, emailText);
  });
});
