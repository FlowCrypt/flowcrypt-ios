import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  NewMessageScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to select recipient from contact list using contact name', async () => {

    const noPublicKeyRecipient = "no.publickey@flowcrypt.com";
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const noPublicKeyError = CommonData.errors.noPublicKey;

    await SplashScreen.login();
    await CreateKeyScreen.setPassPhrase();

    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(noPublicKeyRecipient, emailSubject, emailText);
    await NewMessageScreen.clickSentButton();

    await EmailScreen.enterPassPhrase(passPhrase);
    await EmailScreen.clickOkButton();

    await NewMessageScreen.checkError(noPublicKeyError);
  });
});
