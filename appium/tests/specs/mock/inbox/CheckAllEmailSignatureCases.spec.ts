import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {
  it('user is able to view correct signature badge for all cases', async () => {
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [
        'Signed and encrypted message',
        'Signed only message',
        'Signed only message with detached signature',
        'Test 1',
        'Signed only message where the pubkey is not available',
        'Signed only message that was tempered during transit',
        'Partially signed only message',
      ],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.e2e.email]: MockUserList.e2e.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // signed+encrypted message
      await MailFolderScreen.clickOnEmailBySubject('Signed and encrypted message');

      await EmailScreen.checkEncryptionBadge('encrypted');
      await EmailScreen.checkSignatureBadge('signed');
      await EmailScreen.clickBackButton();

      // signed only message
      await MailFolderScreen.clickOnEmailBySubject('Signed only message');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('signed');
      await EmailScreen.clickBackButton();

      // signed only message with detached signature
      await MailFolderScreen.clickOnEmailBySubject('Signed only message with detached signature');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('signed');
      await EmailScreen.clickBackButton();

      // plain message
      await MailFolderScreen.clickOnEmailBySubject('Test 1');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('not signed');
      await EmailScreen.clickBackButton();

      // signed only message where the pubkey is not available
      await MailFolderScreen.clickOnEmailBySubject('Signed only message where the pubkey is not available');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge(
        'cannot verify signature',
        'no public key A54D 82BE 1521 D20E for email unknown.public.key@example.com',
      );
      await EmailScreen.clickBackButton();

      // signed only message that was tempered during transit
      await MailFolderScreen.clickOnEmailBySubject('Signed only message that was tempered during transit');
      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('cannot verify signature', 'signed digest did not match');
      await EmailScreen.clickBackButton();

      // partially signed only message
      await MailFolderScreen.clickOnEmailBySubject('Partially signed only message');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('only partially signed');
    });
  });
});
