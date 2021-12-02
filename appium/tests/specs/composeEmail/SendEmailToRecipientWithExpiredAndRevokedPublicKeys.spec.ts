import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user with expired/revoked public key produces modal', async () => {

    const expiredPublicKey = CommonData.recipientWithExpiredPublicKey.email;
    const revokedpublicKey = CommonData.recipientWithRevokedPublicKey.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const expiredPublicKeyError = CommonData.errors.expiredPublicKey;
    const revokedPublicKeyError = CommonData.errors.revokedPublicKey;


    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(expiredPublicKey, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(expiredPublicKey, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();

    await NewMessageScreen.checkError(expiredPublicKeyError);

    await NewMessageScreen.clickOkButtonOnError();
    await NewMessageScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(revokedpublicKey, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(revokedpublicKey, emailSubject, emailText);
    await NewMessageScreen.clickSendButton();

    await NewMessageScreen.checkError(revokedPublicKeyError);
  });
});
