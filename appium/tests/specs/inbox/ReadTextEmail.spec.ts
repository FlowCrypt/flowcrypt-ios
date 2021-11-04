import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

    it('user is able to view text email', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = CommonData.simpleEmail.subject;
        const emailText = CommonData.simpleEmail.message;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
