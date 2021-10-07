
import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen
} from '../../screenobjects/all-screens';

import commonData from '../../data/index';

describe('INBOX: ', () => {

    const email = commonData.account.email;
    const pass = commonData.account.password;
    const passPhrase = commonData.account.passPhrase;

    it('user is able to view text email', () => {

        const senderEmail = commonData.sender;
        const emailSubject = 'Test 1';
        const emailText = 'Test email';

        SplashScreen.login(email, pass);
        CreateKeyScreen.setPassPhrase(passPhrase);

        InboxScreen.clickOnUserEmail(senderEmail);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
