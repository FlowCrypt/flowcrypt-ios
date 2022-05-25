import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import DataHelper from "../../../helpers/DataHelper";
import BaseScreen from "../../../screenobjects/base.screen";
import MailFolderHelper from 'tests/helpers/MailFolderHelper';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to send encrypted email when pass phrase session ended + move to trash, delete', async () => {

    const contactEmail = CommonData.recipient.email;
    const contactName = CommonData.recipient.name;
    const emailSubject = CommonData.simpleEmail.subject + DataHelper.uniqueValue();
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhrase;
    const wrongPassPhrase = "wrong";
    const bundleId = CommonData.bundleId.id;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    //Restart app to reset pass phrase memory cache
    await driver.terminateApp(bundleId);
    await driver.activateApp(bundleId);

    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(contactEmail, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo({
      recipients: [contactName],
      subject: emailSubject,
      message: emailText
    });
    //Set wrong pass phrase and check error
    await NewMessageScreen.clickSendButton();
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await BaseScreen.checkModalMessage(wrongPassPhraseError);
    await BaseScreen.clickOkButtonOnError();
    //Set correct pass phrase
    await NewMessageScreen.clickSendButton();
    await EmailScreen.enterPassPhrase(passPhrase);
    await EmailScreen.clickOkButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderHelper.deleteSentEmail(emailSubject, emailText);
  });
});
