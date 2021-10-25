import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

    it('user is able to see encrypted email with pass phrase after restart app', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = 'encrypted message';
        const emailText = 'test test';
        const wrongPassPhrase = 'user is not able to see email';

        const correctPassPhrase = CommonData.account.passPhrase;

        const bundleId = CommonData.bundleId.id;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

        driver.terminateApp(bundleId);

        driver.activateApp(bundleId);

        InboxScreen.clickOnEmailBySubject(emailSubject);

        //try to see encrypted message with wrong pass phrase
        EmailScreen.enterPassPhrase(wrongPassPhrase);
        EmailScreen.clickOkButton();
        EmailScreen.checkWrongPassPhraseErrorMessage();

        //check email after setting correct pass phrase
        EmailScreen.enterPassPhrase(correctPassPhrase);
        EmailScreen.clickSaveButton();
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

        //reopen email without pass phrase
        EmailScreen.clickBackButton();
        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
