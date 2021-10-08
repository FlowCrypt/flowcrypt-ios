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
        const emailSubject = 'Test 1';
        const emailText = 'Test email';

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnUserEmail(senderEmail);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
