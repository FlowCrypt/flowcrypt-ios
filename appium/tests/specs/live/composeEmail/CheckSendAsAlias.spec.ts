import { CommonData } from 'tests/data';
import DataHelper from 'tests/helpers/DataHelper';
import MailFolderHelper from 'tests/helpers/MailFolderHelper';
import {
  MailFolderScreen, NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('user should be able to send email with alias', async () => {

    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const emailSubject = CommonData.alias.subject + DataHelper.uniqueValue();
    const aliasEmail = CommonData.alias.email;
    const emailText = "Test Message"

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickCreateEmail();

    await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
    await NewMessageScreen.checkRecipientLabel([recipientName]);
    await NewMessageScreen.changeFromEmail(aliasEmail);

    await NewMessageScreen.clickSendButton();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderHelper.deleteSentEmail(emailSubject, emailText, aliasEmail);
  });
});
