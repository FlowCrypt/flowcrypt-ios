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

      // signed+encrypted message
      await MailFolderScreen.clickOnEmailBySubject(subject);

      await EmailScreen.checkEncryptionBadge('encrypted');
      await EmailScreen.checkSignatureBadge('signed');
      await EmailScreen.clickBackButton();

      // signed only message
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkOpenedEmail('sender@domain.com', subject, 'Test attachment');
      await EmailScreen.checkAttachment('manifest.json');
    });
  });
});
