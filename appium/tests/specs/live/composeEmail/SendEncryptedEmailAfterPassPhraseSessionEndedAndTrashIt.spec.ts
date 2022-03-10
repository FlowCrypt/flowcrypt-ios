import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  EmailScreen,
  MenuBarScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import DataHelper from "../../../helpers/DataHelper";
import BaseScreen from "../../../screenobjects/base.screen";

describe('COMPOSE EMAIL: ', () => {

  it('user is able to send encrypted email when pass phrase session ended + move to trash, delete', async () => {

    const contactEmail = CommonData.recipient.email;
    const emailSubject = CommonData.simpleEmail.subject + DataHelper.uniqueValue();
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhrase;
    const wrongPassPhrase = "wrong";
    const senderEmail = CommonData.account.email;
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
      recipients: [contactEmail],
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

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickSentButton();
    await MailFolderScreen.checkSentScreen();

    //Check sent email
    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    //Delete sent email
    await EmailScreen.clickDeleteButton();
    await MailFolderScreen.checkSentScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(emailSubject);
    await browser.pause(2000); // give Google API time to process the deletion
    await MailFolderScreen.refreshMailList();
    await MailFolderScreen.checkSentScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(emailSubject);
    //Check email in Trash list
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickTrashButton();
    await MailFolderScreen.checkTrashScreen();
    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    //Remove from Trash
    await EmailScreen.clickDeleteButton();
    await EmailScreen.confirmDelete();
    await MailFolderScreen.checkTrashScreen();
    await browser.pause(2000); // give Google API time to process the deletion
    await MailFolderScreen.refreshMailList();
    await MailFolderScreen.checkTrashScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(emailSubject);
  });
});
