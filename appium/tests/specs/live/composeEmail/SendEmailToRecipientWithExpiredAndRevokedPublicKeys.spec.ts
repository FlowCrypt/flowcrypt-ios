import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user with expired/revoked public key produces modal', async () => {

    const expiredPublicKey = CommonData.recipientWithExpiredPublicKey.email;
    const expiredPublicKeyName = CommonData.recipientWithExpiredPublicKey.name;
    const revokedpublicKey = CommonData.recipientWithRevokedPublicKey.email;
    const revokedpublicKeyName = CommonData.recipientWithRevokedPublicKey.name;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const expiredPublicKeyError = CommonData.errors.expiredPublicKey;
    const revokedPublicKeyError = CommonData.errors.revokedPublicKey;


    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(expiredPublicKey, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [expiredPublicKeyName],
      subject: emailSubject,
      message: emailText
    });
    await NewMessageScreen.clickSendButton();

    await BaseScreen.checkModalMessage(expiredPublicKeyError);

    await BaseScreen.clickOkButtonOnError();
    await NewMessageScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(revokedpublicKey, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [revokedpublicKeyName],
      subject: emailSubject,
      message: emailText
    });
    await NewMessageScreen.clickSendButton();

    await BaseScreen.checkModalMessage(revokedPublicKeyError);
  });
});