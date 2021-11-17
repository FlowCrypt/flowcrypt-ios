import {
  SplashScreen,
  CreateKeyScreen,
  InboxScreen,
  NewMessageScreen,
  EmailScreen,
  MenuBarScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';
import DataHelper from "../../helpers/DataHelper";

describe('COMPOSE EMAIL: ', () => {

  it('user is able to sent encrypted email after reseting pass phrase', async () => {

    const contactEmail = CommonData.secondContact.email;
    const emailSubject = CommonData.simpleEmail.subject + DataHelper.uniqueValue();
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhrase;
    const wrongPassPhrase = "wrong";
    const senderEmail = CommonData.account.email;


    await SplashScreen.login();
    await CreateKeyScreen.setPassPhrase();

    await InboxScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(contactEmail, emailSubject, emailText);
    await NewMessageScreen.checkFilledComposeEmailInfo(contactEmail, emailSubject, emailText);
    //Set wrong pass phrase and check error
    await NewMessageScreen.clickSentButton();
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await NewMessageScreen.checkError(wrongPassPhraseError);
    await NewMessageScreen.clickOkButtonOnError();
    //Set correct pass phrase
    await NewMessageScreen.clickSentButton();
    await EmailScreen.enterPassPhrase(passPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkSentEmailMessage();

    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.clickSentButton();
    //Check sent email
    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

  });
});
