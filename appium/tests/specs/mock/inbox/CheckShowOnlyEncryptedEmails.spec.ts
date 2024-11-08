import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MailFolderScreen, MenuBarScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {
  it('user is able to see only encrypted emails when he clicks show only encrypted emails button', async () => {
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    const plainEmailSubject = 'Honor reply-to address - plain';
    const encryptedEmailSubject = 'Encrypted email with public key attached';
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [plainEmailSubject, encryptedEmailSubject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Check if both encrypted & plain emails are present
      await MailFolderScreen.checkEmailIsDisplayed(plainEmailSubject);
      await MailFolderScreen.checkEmailIsDisplayed(encryptedEmailSubject);

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickShowOnlyEncryptedEmailsToggle();
      await browser.pause(1000);
      await MenuBarScreen.clickInboxButton();

      // Now check if plain email is not present
      await MailFolderScreen.checkEmailIsNotDisplayed(plainEmailSubject);
    });
  });
});
