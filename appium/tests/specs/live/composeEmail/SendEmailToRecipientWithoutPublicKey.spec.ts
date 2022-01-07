import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key produces password modal', async () => {

    const recipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;

    const passwordModalMessage = CommonData.recipientWithoutPublicKey.modalMessage;
    const emptyPasswordMessage = CommonData.recipientWithoutPublicKey.emptyPasswordMessage;
    const addedPasswordMessage = CommonData.recipientWithoutPublicKey.addedPasswordMessage;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(recipient, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();
    await BaseScreen.checkModalMessage(passwordModalMessage);
    await NewMessageScreen.clickCancelButton();
    await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

    await NewMessageScreen.deleteAddedRecipient(0, 'gray');

    await NewMessageScreen.setAddRecipient(recipient);
    await NewMessageScreen.clickSendButton();
    await BaseScreen.checkModalMessage(passwordModalMessage);
    await NewMessageScreen.clickCancelButton();
    await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

    await NewMessageScreen.clickPasswordCell();
    await NewMessageScreen.setMessagePassword(emailPassword);
    await NewMessageScreen.checkPasswordCell(addedPasswordMessage);
  });
});
