import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('COMPOSE EMAIL: ', () => {

    it('user is able to select recipient from contact list using name', () => {

        const contactEmail = CommonData.contact.email;
        const contactName = CommonData.contact.name;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();

        NewMessageScreen.setAddRecipientByName(contactName, contactEmail);
        NewMessageScreen.checkAddedRecipient(contactEmail);
    });
});
