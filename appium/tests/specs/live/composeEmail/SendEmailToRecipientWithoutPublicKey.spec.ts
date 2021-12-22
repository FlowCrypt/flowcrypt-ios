import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key produces modal', async () => {

    const noPublicKeyRecipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const noPublicKeyError = CommonData.errors.noPublicKey;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();

    await BaseScreen.checkModalMessage(noPublicKeyError);
  });
});
