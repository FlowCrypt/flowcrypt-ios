import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  EmailScreen,
  MailFolderScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {
  it('check caret position for reply and forward', async () => {
    const mockApi = new MockApi();
    const subject = 'Test 1';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(subject);

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
