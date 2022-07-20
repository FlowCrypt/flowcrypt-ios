import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  MenuBarScreen
} from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {

  it('user is able to archive and move to inbox email', async () => {
    const mockApi = new MockApi();
    const testMessageSubject = 'Signed and encrypted message';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [testMessageSubject, 'Signed only message'],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // First find email and archieve it
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
      await EmailScreen.clickArchiveButton();
      // Check if archieved email is not displayed in inbox screen
      await MailFolderScreen.checkEmailIsNotDisplayed(testMessageSubject);

      //  Go to all mail screen
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickAllMailButton();

      // Archieve email should be listed in all mail screen
      // Move email to inbox
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
      await EmailScreen.clickMoveToInboxButton();

      // Check if email is displayed correctly in inbox screen.
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
    });
  });
});
