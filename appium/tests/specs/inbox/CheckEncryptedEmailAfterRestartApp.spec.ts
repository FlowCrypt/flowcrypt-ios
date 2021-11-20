import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

describe('INBOX: ', () => {

  it('user is able to see encrypted email with pass phrase after restart app', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmail.subject;
    const emailText = CommonData.encryptedEmail.message;
    const wrongPassPhrase = 'wrong';

    const correctPassPhrase = CommonData.account.passPhrase;

    const bundleId = CommonData.bundleId.id;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await InboxScreen.checkInboxScreen();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    await driver.terminateApp(bundleId);
    await driver.activateApp(bundleId);

    await InboxScreen.clickOnEmailBySubject(emailSubject);

    //try to see encrypted message with wrong pass phrase
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkWrongPassPhraseErrorMessage();

    //check email after setting correct pass phrase
    await EmailScreen.enterPassPhrase(correctPassPhrase);
    await EmailScreen.clickSaveButton();
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

    //reopen email without pass phrase
    await EmailScreen.clickBackButton();
    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
  });
});
