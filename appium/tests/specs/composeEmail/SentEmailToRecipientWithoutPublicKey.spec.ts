import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  NewMessageScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key prouces modal', async () => {

    const noPublicKeyRecipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const noPublicKeyError = CommonData.errors.noPublicKey;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();

    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.clickSentButton();

    await EmailScreen.enterPassPhrase(passPhrase);
    await EmailScreen.clickOkButton();

    await NewMessageScreen.checkError(noPublicKeyError);
  });
});
