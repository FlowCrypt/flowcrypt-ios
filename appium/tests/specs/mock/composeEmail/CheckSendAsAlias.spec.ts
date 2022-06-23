import { MockApi } from 'api-mocks/mock';
import { CommonData } from 'tests/data';
import {
  MailFolderScreen, NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('user should be able to send email with alias', async () => {

    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const emailSubject = CommonData.alias.subject;
    const aliasEmail = CommonData.alias.email;
    const emailText = CommonData.alias.message;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
      await NewMessageScreen.checkRecipientLabel([recipientName]);
      await NewMessageScreen.changeFromEmail(aliasEmail);

      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkInboxScreen();
    });
  });
});
