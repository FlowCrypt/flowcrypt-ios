import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { EmailScreen, MailFolderScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {
  it('check if canary email is decrypted successfully', async () => {
    const mockApi = new MockApi();
    const subject = 'Canary Mail PGP encrypted emails cannot be read by Flowcrypt recipient';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Check if message is decrypted correctly.
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkEmailText(
        'Email body cannot be read. Flowcrypt says email received is not encrypted and not signed, but it is PGP encrypted and signed by Canary Mail when sent',
      );
    });
  });
});
