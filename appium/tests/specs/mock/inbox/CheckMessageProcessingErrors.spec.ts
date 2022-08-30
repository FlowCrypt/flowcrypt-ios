import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from 'tests/screenobjects/base.screen';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('INBOX: ', () => {

  it('user is able to view message processing errors', async () => {

    const decryptErrorBadgeText = CommonData.decryptErrorBadge.badgeText;

    // Const for MDC hash mismatch message
    const encryptedMDCSender = CommonData.encryptedMDCHashMismatchEmail.senderName;
    const encryptedMDCSubject = CommonData.encryptedMDCHashMismatchEmail.subject;
    const encryptedMDCText = CommonData.encryptedMDCHashMismatchEmail.message;

    // Const for message encrypted for another public key
    const encryptedForAnotherPublicKeySubject = CommonData.encryptedForAnotherPublicKeyEmail.subject;
    const encryptedForAnotherPublicKeyName = CommonData.encryptedForAnotherPublicKeyEmail.senderName;
    const encryptedForAnotherPublicKeyText = CommonData.encryptedForAnotherPublicKeyEmail.message;

    // Const for encrypted for a wrong checksum message
    const wrongChecksumSubject = CommonData.wrongChecksumEmail.subject;
    const wrongChecksumName = CommonData.wrongChecksumEmail.senderName;
    const wrongChecksumText = CommonData.wrongChecksumEmail.message;

    const notIntegrityProtectedSubject = CommonData.notIntegrityProtected.subject;
    const notIntegrityProtectedSender = CommonData.notIntegrityProtected.senderName;
    const notIntegrityProtectedText = CommonData.notIntegrityProtected.message;

    const keyMismatchSubject = CommonData.keyMismatch.subject;
    const keyMismatchName = CommonData.keyMismatch.senderName;
    const keyMismatchText = CommonData.keyMismatch.message;
    const keyMismatchEncryptedBadge = CommonData.keyMismatch.encryptedBadgeText;
    const keyMismatchSignatureBadge = CommonData.keyMismatch.signatureBadgeText;
    const keyMismatchAttachmentError = CommonData.errors.attachmentDecryptKeyMismatchError;
    const firstAttachmentName = CommonData.keyMismatch.firstAttachmentName;
    const firstAttachmentBody = CommonData.keyMismatch.firstAttachmentBody;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [
        'encrypted - MDC hash mismatch - modification detected - should fail',
        'message encrypted for another public key (only one pubkey used)',
        'wrong checksum',
        'not integrity protected - should show a warning and not decrypt automatically',
        'key mismatch unexpectedly produces a modal'
      ],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.sunit.email]: MockUserList.sunit.pub!,
        [MockUserList.flowcryptCompatibility.email]: MockUserList.flowcryptCompatibility.pub!
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Checking error for MDC hash mismatch message
      await MailFolderScreen.clickOnEmailBySubject(encryptedMDCSubject);
      await EmailScreen.checkOpenedEmail(encryptedMDCSender, encryptedMDCSubject, encryptedMDCText);
      await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

      await EmailScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();

      // Checking error message encrypted for another public key
      await MailFolderScreen.clickOnEmailBySubject(encryptedForAnotherPublicKeySubject);
      await EmailScreen.checkOpenedEmail(encryptedForAnotherPublicKeyName, encryptedForAnotherPublicKeySubject, encryptedForAnotherPublicKeyText);
      await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

      await EmailScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();

      // Checking error for wrong checksum message
      await MailFolderScreen.clickOnEmailBySubject(wrongChecksumSubject);
      await EmailScreen.checkOpenedEmail(wrongChecksumName, wrongChecksumSubject, wrongChecksumText);
      await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

      await EmailScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();

      // Checking error for integrity protected message
      await MailFolderScreen.clickOnEmailBySubject(notIntegrityProtectedSubject);
      await EmailScreen.checkOpenedEmail(notIntegrityProtectedSender, notIntegrityProtectedSubject, notIntegrityProtectedText);
      await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

      await EmailScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();

      // Checking if message body is rendered with key mismatch
      await MailFolderScreen.clickOnEmailBySubject(keyMismatchSubject);
      await EmailScreen.checkOpenedEmail(keyMismatchName, keyMismatchSubject, keyMismatchText);
      await EmailScreen.checkEncryptionBadge(keyMismatchEncryptedBadge);
      await EmailScreen.checkSignatureBadge(keyMismatchSignatureBadge);
      await EmailScreen.checkAttachment(firstAttachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await BaseScreen.checkModalMessage(keyMismatchAttachmentError);
      await EmailScreen.clickDownloadButton();
      await EmailScreen.checkAttachmentTextView(firstAttachmentBody);
    });
  });
});
