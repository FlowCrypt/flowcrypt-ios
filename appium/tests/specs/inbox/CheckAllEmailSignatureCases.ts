import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  EmailScreen
} from '../../screenobjects/all-screens';

describe('INBOX: ', () => {

  it('user is able to view correct signature badge for all cases', async () => {

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await InboxScreen.checkInboxScreen();

    // signed+encrypted message
    const s1 = 'Signed and encrypted message';
    await InboxScreen.clickOnEmailBySubject(s1);
    await EmailScreen.checkOpenedEmail('e2e.enterprise.test@flowcrypt.com', s1, 'Signed and encrypted message.');
    await EmailScreen.checkEncryptionBadge('encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    // singed only message
    const s2 = 'Signed only message';
    await InboxScreen.clickOnEmailBySubject(s2);
    await EmailScreen.checkOpenedEmail('e2e.enterprise.test@flowcrypt.com', s2, s2);
    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    // signed only message with detached signature
    const s3 = 'Signed only message with detached signature';
    await InboxScreen.clickOnEmailBySubject(s3);
    await EmailScreen.checkOpenedEmail('e2e.enterprise.test@flowcrypt.com', s3, s3);
    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    // plain message
    const s4 = 'Test 1';
    await InboxScreen.scrollDown();
    await InboxScreen.clickOnEmailBySubject(s4);
    await EmailScreen.checkOpenedEmail('dmitry@flowcrypt.com', s4, 'Test email');
    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('not signed');    
    await EmailScreen.clickBackButton();

    // TODO signed-only message where the pubkey is not available

    // TODO signed-only message that was tempered during transit
  });
});
