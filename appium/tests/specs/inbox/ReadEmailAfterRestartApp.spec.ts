import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

    it('user is able to see encrypted inbox email without setting pass phrase after restart app', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = 'Test 1';
        const emailText = 'Test email';

        const bundleId = CommonData.bundleId.id;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnUserEmail(senderEmail);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

        driver.terminateApp(bundleId);

        driver.activateApp(bundleId);

        InboxScreen.clickOnUserEmail(senderEmail);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
