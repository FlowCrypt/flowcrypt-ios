import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

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

    //  Const for not integrity protected message BUG:https://github.com/FlowCrypt/flowcrypt-ios/issues/1144
    // const notIntegrityProtectedSubject = CommonData.notIntegrityProtected.subject;
    // // const notIntegrityProtectedEmail = CommonData.notIntegrityProtected.senderEmail;
    // // const notIntegrityProtectedText = CommonData.notIntegrityProtected.message;
    // const notIntegrityProtectedEncryptionBadge = CommonData.notIntegrityProtected.encryptionBadgeText;
    // const notIntegrityProtectedSignatureBadge = CommonData.notIntegrityProtected.signatureBadgeText;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Checking MDC hash mismatch message
    await MailFolderScreen.searchEmailBySubject(encryptedMDCSubject);
    await MailFolderScreen.clickOnEmailBySubject(encryptedMDCSubject);
    await EmailScreen.enterPassPhrase();
    await EmailScreen.clickOkButton();
    await EmailScreen.checkOpenedEmail(encryptedMDCEmail, encryptedMDCSubject, encryptedMDCText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking message encrypted for another public key
    await MailFolderScreen.searchEmailBySubject(encryptedForAnotherPublicKeySubject);
    await MailFolderScreen.clickOnEmailBySubject(encryptedForAnotherPublicKeySubject);
    await EmailScreen.checkOpenedEmail(encryptedForAnotherPublicKeyEmail, encryptedForAnotherPublicKeySubject, encryptedForAnotherPublicKeyText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    await EmailScreen.clickBackButton();
    await SearchScreen.clickBackButton();
    await MailFolderScreen.checkInboxScreen();

    // Checking wrong checksum message
    await MailFolderScreen.searchEmailBySubject(wrongChecksumSubject);
    await MailFolderScreen.clickOnEmailBySubject(wrongChecksumSubject);
    await EmailScreen.checkOpenedEmail(wrongChecksumEmail, wrongChecksumSubject, wrongChecksumText);
    await EmailScreen.checkEncryptionBadge(decryptErrorBadgeText);

    // Checking integrity protected message BUG:https://github.com/FlowCrypt/flowcrypt-ios/issues/1144

    // await EmailScreen.clickBackButton();
    // await SearchScreen.clickBackButton();
    // await MailFolderScreen.checkInboxScreen();

    // await MailFolderScreen.searchEmailBySubject(notIntegrityProtectedSubject);
    // await MailFolderScreen.clickOnEmailBySubject(notIntegrityProtectedSubject);
    // // await EmailScreen.checkOpenedEmail(notIntegrityProtectedEmail, notIntegrityProtectedSubject, notIntegrityProtectedText);
    // await EmailScreen.checkEncryptionBadge(notIntegrityProtectedEncryptionBadge);
    // await EmailScreen.checkSignatureBadge(notIntegrityProtectedSignatureBadge);
  });
});
