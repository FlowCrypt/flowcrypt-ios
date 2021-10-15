import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('check filled compose email after reopening app', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = 'TestSubject';
        const emailText = 'Test email';

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();
        NewMessageScreen.setComposeEmail(senderEmail, emailSubject, emailText);
        NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, emailSubject, emailText);

        driver.background(3);

        NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, emailSubject, emailText);
    });
});
