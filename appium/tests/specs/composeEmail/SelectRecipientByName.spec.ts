import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('user is able to select recipient from contact list using name', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = 'TestSubject';
        const emailText = 'Test email';
        const recipientName = 'Dima';

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();
        NewMessageScreen.setComposeEmailByName(recipientName, senderEmail, emailSubject, emailText);
        NewMessageScreen.checkFilledComposeEmailInfo(senderEmail, emailSubject, emailText);
    });
});
