import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  NewMessageScreen,
  EmailScreen,
  MenuBarScreen,
  SentScreen,
  TrashScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';
import DataHelper from "../../helpers/DataHelper";

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
    await InboxScreen.checkInboxScreen();

    //Restart app to reset pass phrase memory cache
    await driver.terminateApp(bundleId);
    await driver.activateApp(bundleId);

    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(contactEmail, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(contactEmail, emailSubject, emailText);
    //Set wrong pass phrase and check error
    await NewMessageScreen.clickSendButton();
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await NewMessageScreen.checkError(wrongPassPhraseError);
    await NewMessageScreen.clickOkButtonOnError();
    //Set correct pass phrase
    await NewMessageScreen.clickSendButton();
    await EmailScreen.enterPassPhrase(passPhrase);
    await EmailScreen.clickOkButton();
    await InboxScreen.checkInboxScreen();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickSentButton();
    await SentScreen.checkSentScreen();

    //Check sent email
    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    //Delete sent email
    await EmailScreen.clickDeleteButton();
    await SentScreen.checkSentScreen();
    await SentScreen.checkEmailIsNotDisplayed(emailSubject);
    await browser.pause(2000); // give Google API time to process the deletion
    await SentScreen.refreshSentList();
    await SentScreen.checkSentScreen();
    await SentScreen.checkEmailIsNotDisplayed(emailSubject);
    //Check email in Trash list
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickTrashButton();
    await TrashScreen.checkTrashScreen();
    await InboxScreen.clickOnEmailBySubject(emailSubject);
    //Remove from Trash
    await EmailScreen.clickDeleteButton();
    await EmailScreen.confirmDelete();
    await TrashScreen.checkTrashScreen();
    await browser.pause(2000); // give Google API time to process the deletion
    await TrashScreen.refreshTrashList();
    await TrashScreen.checkTrashScreen();
    await TrashScreen.checkEmailIsNotDisplayed(emailSubject);
  });
});
