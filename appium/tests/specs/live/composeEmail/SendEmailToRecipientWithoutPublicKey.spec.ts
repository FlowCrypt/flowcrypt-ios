import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key produces modal', async () => {

    const recipientWithPasswordSupport = CommonData.recipientWithoutPublicKey.emailWithPasswordSupport;
    const recipientWithoutPasswordSupport = CommonData.recipientWithoutPublicKey.emailWithoutPasswordSupport;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;
    const noPubKeyErrorMessage = CommonData.errors.noPublicKey;
    const passwordModalMessage = CommonData.recipientWithoutPublicKey.modalMessage;
    const emptyPasswordMessage = CommonData.recipientWithoutPublicKey.emptyPasswordMessage;
    const addedPasswordMessage = CommonData.recipientWithoutPublicKey.addedPasswordMessage;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientWithoutPasswordSupport, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(recipientWithoutPasswordSupport, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();
    await NewMessageScreen.checkModalText(noPubKeyErrorMessage);
    await BaseScreen.clickOkButtonOnError();
    await NewMessageScreen.clickBackButton();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientWithPasswordSupport, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(recipientWithPasswordSupport, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();
    await NewMessageScreen.checkModalText(passwordModalMessage);
    await NewMessageScreen.clickCancelButton();
    await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

    await NewMessageScreen.clickPasswordCell();
    await NewMessageScreen.setMessagePassword(emailPassword);
    await NewMessageScreen.checkPasswordCell(addedPasswordMessage);
  });
});
