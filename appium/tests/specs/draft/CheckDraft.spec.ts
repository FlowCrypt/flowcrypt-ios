import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    NewMessageScreen,
    MenuBarScreen,
    EmailScreen
} from '../../screenobjects/all-screens';
import DataHelper from "../../helpers/DataHelper";

describe('DRAFT: ', () => {

    it('check draft after filling out compose email', () => {

        const recipientEmail = 'dmitry@flowcrypt.com';
        const emailSubject = 'TestSubject' + DataHelper.uniqueValue();
        const emailText = 'Test email';

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickCreateEmail();
        NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
        NewMessageScreen.checkFilledComposeEmailInfo(recipientEmail, emailSubject, emailText);

        NewMessageScreen.clickBackButton();
        MenuBarScreen.clickMenuIcon();
        MenuBarScreen.clickDraftButton();

        // check draft
        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(recipientEmail, emailSubject, emailText);
    });
});
