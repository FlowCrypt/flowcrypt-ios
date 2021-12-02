import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user with revoked public key produces modal', async () => {

    const noPublicKeyRecipient = CommonData.recipientWithRevokedPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const noPublicKeyError = CommonData.errors.revokedPublicKey;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();

    await NewMessageScreen.checkError(noPublicKeyError);
  });
});
