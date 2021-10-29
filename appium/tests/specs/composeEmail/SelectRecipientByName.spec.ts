import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('user is able to select recipient from contact list using name', () => {

        const recipientEmail = 'dmitry@flowcrypt.com';
        const recipientName = 'Dima';

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();

        NewMessageScreen.setAddRecipientByName(recipientName, recipientEmail);
        NewMessageScreen.checkAddedRecipient(recipientEmail);
    });
});
