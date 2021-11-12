import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('check filled compose email after reopening app', () => {

        const recipientEmail = CommonData.contact.email;
        const emailSubject = CommonData.simpleEmail.subject;
        const emailText = CommonData.simpleEmail.message;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();
        NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
        NewMessageScreen.checkFilledComposeEmailInfo(recipientEmail, emailSubject, emailText);

        driver.background(3);

        NewMessageScreen.checkFilledComposeEmailInfo(recipientEmail, emailSubject, emailText);
    });
});
