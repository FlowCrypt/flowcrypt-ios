import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {
  it('user is able to view correct attachment for email sent via encrypted contact page', async () => {
    const mockApi = new MockApi();
    const subject = 'Test encrypted message sent via encrypted contact page with attachment';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // check if email is decrypted successfully
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkOpenedEmail(
        'sender@domain.com',
        subject,
        'Test encrypted attachment sent via encrypted contact page',
      );
      await EmailScreen.checkAttachment('manifest.json.pgp');
    });
  });
});
