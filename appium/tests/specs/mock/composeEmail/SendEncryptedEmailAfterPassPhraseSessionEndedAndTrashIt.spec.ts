import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";
import MailFolderHelper from 'tests/helpers/MailFolderHelper';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to send encrypted email when pass phrase session ended + move to trash, delete', async () => {

    const contactEmail = CommonData.contact.email;
    const contactName = CommonData.contact.contactName;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhrase;
    const wrongPassPhrase = "wrong";
    const processArgs = CommonData.mockProcessArgs;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Restart app to reset pass phrase memory cache
      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(contactEmail, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [contactName],
        subject: emailSubject,
        message: emailText
      });

      // Set wrong pass phrase and check error
      await NewMessageScreen.clickSendButton();
      await EmailScreen.enterPassPhrase(wrongPassPhrase);
      await EmailScreen.clickOkButton();
      await BaseScreen.checkModalMessage(wrongPassPhraseError);
      await BaseScreen.clickOkButtonOnError();

      // Set correct pass phrase
      await NewMessageScreen.clickSendButton();
      await EmailScreen.enterPassPhrase(passPhrase);
      await EmailScreen.clickOkButton();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderHelper.deleteSentEmail(emailSubject, emailText);
    });
  });
});
