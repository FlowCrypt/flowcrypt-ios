import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

    it('user is able to see plain email without setting pass phrase after restart app', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = CommonData.simpleEmail.subject;
        const emailText = CommonData.simpleEmail.message;

        const bundleId = CommonData.bundleId.id;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);

        driver.terminateApp(bundleId);

        driver.activateApp(bundleId);

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    });
});
