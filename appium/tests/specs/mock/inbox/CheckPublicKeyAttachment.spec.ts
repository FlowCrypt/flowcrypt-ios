import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { EmailScreen, MailFolderScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';
import { CommonData } from 'tests/data';

describe('COMPOSE EMAIL: ', () => {
  it('check public key attachment', async () => {
    const mockApi = new MockApi();
    const testSubject = 'Test public key attachment for encrypted message';
    const testInnerPublicKeySubject = 'Test public key attachment for inline public key';

    const publicKeyEmail = CommonData.inlinePublicKeyAttachment.publicKeyEmail;
    const publicKeyFingerprint = CommonData.inlinePublicKeyAttachment.publicKeyFingerPrint;
    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [testSubject, testInnerPublicKeySubject],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Check public key import view for encrypted message
      await MailFolderScreen.clickOnEmailBySubject(testSubject);
      await EmailScreen.checkPublicKeyImportView(publicKeyEmail, publicKeyFingerprint, false);

      await EmailScreen.clickBackButton();

      // Check public key import view for inline public key attachment
      await MailFolderScreen.clickOnEmailBySubject(testInnerPublicKeySubject);
      await EmailScreen.checkPublicKeyImportView(publicKeyEmail, publicKeyFingerprint, false);
    });
  });
});
