import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from 'tests/screenobjects/base.screen';

describe('INBOX: ', () => {

  it('user is able to view message processing errors', async () => {

    const decryptErrorBadgeText = CommonData.decryptErrorBadge.badgeText;

    //  Const for MDC hash mismatch message
    const encryptedMDCEmail = CommonData.encryptedMDCHashMismatchEmail.senderEmail;
    const encryptedMDCSubject = CommonData.encryptedMDCHashMismatchEmail.subject;
    const encryptedMDCText = CommonData.encryptedMDCHashMismatchEmail.message;

    //  Const for message encrypted for another public key
    const encryptedForAnotherPublicKeySubject = CommonData.encryptedForAnotherPublicKeyEmail.subject;
    const encryptedForAnotherPublicKeyEmail = CommonData.encryptedForAnotherPublicKeyEmail.senderEmail;
    const encryptedForAnotherPublicKeyText = CommonData.encryptedForAnotherPublicKeyEmail.message;

    //  Const for encrypted for a wrong checksum message
    const wrongChecksumSubject = CommonData.wrongChecksumEmail.subject;
    const wrongChecksumEmail = CommonData.wrongChecksumEmail.senderEmail;
    const wrongChecksumText = CommonData.wrongChecksumEmail.message;

    const notIntegrityProtectedSubject = CommonData.notIntegrityProtected.subject;
    const notIntegrityProtectedEmail = CommonData.notIntegrityProtected.senderEmail;
    const notIntegrityProtectedText = CommonData.notIntegrityProtected.message;

    const keyMismatchSubject = CommonData.keyMismatch.subject;
    const keyMismatchEmail = CommonData.keyMismatch.senderEmail;
    const keyMismatchText = CommonData.keyMismatch.message;
    const keyMismatchEncryptedBadge = CommonData.keyMismatch.encryptedBadgeText;
    const keyMismatchSignatureBadge= CommonData.keyMismatch.signatureBadgeText;
    const keyMismatchAttachmentError = CommonData.errors.attachmentDecryptKeyMismatchError;
    const firstAttachmentName = CommonData.keyMismatch.firstAttachmentName;
    const firstAttachmentBody = CommonData.keyMismatch.firstAttachmentBody;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Checking error for MDC hash mismatch message
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(encryptedMDCSubject);
    await EmailScreen.checkOpenedEmail(encryptedMDCEmail, encryptedMDCSubject, encryptedMDCText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking error message encrypted for another public key
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(encryptedForAnotherPublicKeySubject);
    await EmailScreen.checkOpenedEmail(encryptedForAnotherPublicKeyEmail, encryptedForAnotherPublicKeySubject, encryptedForAnotherPublicKeyText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking error for wrong checksum message
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(wrongChecksumSubject);
    await EmailScreen.checkOpenedEmail(wrongChecksumEmail, wrongChecksumSubject, wrongChecksumText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    // Checking error for integrity protected message
    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailBySubject(notIntegrityProtectedSubject);
    await MailFolderScreen.clickOnEmailBySubject(notIntegrityProtectedSubject);
    await EmailScreen.checkOpenedEmail(notIntegrityProtectedEmail, notIntegrityProtectedSubject, notIntegrityProtectedText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    // Checking if message body is rendered with key mismatch
    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailBySubject(keyMismatchSubject);
    await MailFolderScreen.clickOnEmailBySubject(keyMismatchSubject);
    await EmailScreen.checkOpenedEmail(keyMismatchEmail, keyMismatchSubject, keyMismatchText);
    await EmailScreen.checkEncryptionBadge(keyMismatchEncryptedBadge);
    await EmailScreen.checkSignatureBadge(keyMismatchSignatureBadge);
    await EmailScreen.checkAttachment(firstAttachmentName);
    await EmailScreen.clickOnAttachmentCell();
    await BaseScreen.checkModalMessage(keyMismatchAttachmentError);
    await EmailScreen.clickDownloadButton();
    await EmailScreen.checkAttachmentTextView(firstAttachmentBody);
  });
});
