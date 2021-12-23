import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

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

    const keyMismatchUnexpectedlySugject = CommonData.keyMismatchUnexpectedly.subject;
    const keyMismatchUnexpectedlyEmail = CommonData.keyMismatchUnexpectedly.senderEmail;
    const keyMismatchUnexpectedlyText = CommonData.keyMismatchUnexpectedly.message;
    const keyMismatchUnexpectedlyEncryptedBadge = CommonData.keyMismatchUnexpectedly.encryptedBadgeText;
    const keyMismatchUnexpectedlySignatureBadge= CommonData.keyMismatchUnexpectedly.signatureBadgeText;
    const firstAttachmentName = CommonData.keyMismatchUnexpectedly.firstAttachmentName;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Checking MDC hash mismatch message
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(encryptedMDCSubject);
    await EmailScreen.checkOpenedEmail(encryptedMDCEmail, encryptedMDCSubject, encryptedMDCText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking message encrypted for another public key
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(encryptedForAnotherPublicKeySubject);
    await EmailScreen.checkOpenedEmail(encryptedForAnotherPublicKeyEmail, encryptedForAnotherPublicKeySubject, encryptedForAnotherPublicKeyText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking wrong checksum message
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject(wrongChecksumSubject);
    await EmailScreen.checkOpenedEmail(wrongChecksumEmail, wrongChecksumSubject, wrongChecksumText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    // Checking integrity protected message
    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailBySubject(notIntegrityProtectedSubject);
    await MailFolderScreen.clickOnEmailBySubject(notIntegrityProtectedSubject);
    await EmailScreen.checkOpenedEmail(notIntegrityProtectedEmail, notIntegrityProtectedSubject, notIntegrityProtectedText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    // Checking key mismatch unexpectedly produces a modal message
    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailBySubject(keyMismatchUnexpectedlySugject);
    await MailFolderScreen.clickOnEmailBySubject(keyMismatchUnexpectedlySugject);
    await EmailScreen.checkOpenedEmail(keyMismatchUnexpectedlyEmail, keyMismatchUnexpectedlySugject, keyMismatchUnexpectedlyText);
    await EmailScreen.checkEncryptionBadge(keyMismatchUnexpectedlyEncryptedBadge);
    await EmailScreen.checkSignatureBadge(keyMismatchUnexpectedlySignatureBadge);
    await EmailScreen.checkAttachment(firstAttachmentName);
  });
});
