import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';

describe('INBOX: ', () => {

  it('user is able to see encrypted email with pass phrase after restart app', async () => {

    const senderName = CommonData.encryptedEmailWithAttachment.sender;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const wrongPassPhrase = 'wrong';

    const correctPassPhrase = CommonData.account.passPhrase;
    const processArgs = CommonData.mockProcessArgs;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      // try to see encrypted message with wrong pass phrase
      await EmailScreen.enterPassPhrase(wrongPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkWrongPassPhraseErrorMessage();

      // check email after setting correct pass phrase
      await EmailScreen.enterPassPhrase(correctPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

      // reopen email without pass phrase
      await EmailScreen.clickBackButton();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
    });
  });
});
