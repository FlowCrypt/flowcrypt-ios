import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

describe('INBOX: ', () => {

  it('user is able to view correct signature badge for all cases', async () => {
    await MockApi.e2eMock.withMockedApis(async () => {
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
      await EmailScreen.checkSignatureBadge('cannot verify signature: no public key A54D82BE1521D20E');
      await EmailScreen.clickBackButton();

      // signed only message that was tempered during transit
      await MailFolderScreen.clickOnEmailBySubject('Signed only message that was tempered during transit');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('bad signature');
      await EmailScreen.clickBackButton();

      // partially signed only message
      await MailFolderScreen.clickOnEmailBySubject('Partially signed only message');

      await EmailScreen.checkEncryptionBadge('not encrypted');
      await EmailScreen.checkSignatureBadge('only partially signed');
    });
  });
});
