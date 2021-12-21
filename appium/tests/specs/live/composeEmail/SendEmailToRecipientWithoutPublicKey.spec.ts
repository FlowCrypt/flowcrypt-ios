import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key produces modal', async () => {

    const noPublicKeyRecipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;
    const modalMessage = CommonData.recipientWithoutPublicKey.modalMessage;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();

    await NewMessageScreen.checkModalText(modalMessage);
    await NewMessageScreen.clickCancelButton();
    await NewMessageScreen.checkPasswordCell("Tap to add password for recipients who don't have encryption set up.");

    await NewMessageScreen.clickPasswordCell();
    await NewMessageScreen.setMessagePassword(emailPassword);
    await NewMessageScreen.checkPasswordCell("Web portal password added");
  });
});
