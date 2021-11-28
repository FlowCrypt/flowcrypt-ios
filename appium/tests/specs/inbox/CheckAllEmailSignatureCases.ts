import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../screenobjects/all-screens';

describe('INBOX: ', () => {

  it('user is able to view correct signature badge for all cases', async () => {

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // signed+encrypted message
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.checkScreen();
    await SearchScreen.searchAndClickEmailBySubject('Signed and encrypted message');

    await EmailScreen.checkEncryptionBadge('encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();

    // singed only message
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.checkScreen();
    await SearchScreen.searchAndClickEmailBySubject('Signed only message');

    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();

    // signed only message with detached signature
    await MailFolderScreen.clickSearchButton();
    await SearchScreen.searchAndClickEmailBySubject('Signed only message with detached signature');

    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('signed');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();

    // plain message
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.checkScreen();
    await SearchScreen.searchAndClickEmailBySubject('Test 1');
    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('not signed');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();

    // signed only message where the pubkey is not available
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.checkScreen();
    await SearchScreen.searchAndClickEmailBySubject('Signed only message where the pubkey is not available');
    await EmailScreen.checkEncryptionBadge('decrypt error');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();

    // signed only message that was tempered during transit
    await MailFolderScreen.clickSearchButton();

    await SearchScreen.checkScreen();
    await SearchScreen.searchAndClickEmailBySubject('Signed only message that was tempered during transit');

    await EmailScreen.checkEncryptionBadge('not encrypted');
    await EmailScreen.checkSignatureBadge('bad signature');
    await EmailScreen.clickBackButton();

    await SearchScreen.checkScreen();
    await SearchScreen.clickBackButton();
  });
});
