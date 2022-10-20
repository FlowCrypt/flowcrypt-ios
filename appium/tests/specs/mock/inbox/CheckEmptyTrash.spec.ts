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

  it('user is able to empty trash and delete all emails', async () => {
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

      // First find email and delete it
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
      await EmailScreen.clickDeleteButton();
      // Check if deleted email is not displayed in inbox screen
      await MailFolderScreen.checkEmailIsNotDisplayed(testMessageSubject);

      //  Go to trash screen
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickTrashButton();

      // Check if app not crashes after going back from message screen
      await MailFolderScreen.clickOnEmailBySubject(testMessageSubject);
      await EmailScreen.clickBackButton();
      // Empty trash (it would throw error if empty folder button is not present)
      await MailFolderScreen.emptyFolder();

      await MailFolderScreen.checkEmailIsNotDisplayed(testMessageSubject);
    });
  });
});
