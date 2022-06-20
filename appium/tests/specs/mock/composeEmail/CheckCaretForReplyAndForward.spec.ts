import { MockApi } from 'api-mocks/mock';
import {
  EmailScreen,
  MailFolderScreen, NewMessageScreen,
  SearchScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check caret position for reply and forward', async () => {
    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // signed+encrypted message
      await MailFolderScreen.clickSearchButton();

      await SearchScreen.searchAndClickEmailBySubject('Signed and encrypted message');

      // check message text field focus for reply message
      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkMessageFieldFocus();
      await NewMessageScreen.clickBackButton();

      // check recipient text field focus for forward message
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickForwardButton();
      await NewMessageScreen.checkRecipientTextFieldFocus();
      await NewMessageScreen.clickBackButton();
    });
  });
});
