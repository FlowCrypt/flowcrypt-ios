import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  SearchScreen,
  EmailScreen,
  MenuBarScreen,
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';

describe('LOGIN: ', () => {
  // Temporary disabled because of https://github.com/FlowCrypt/flowcrypt-ios/issues/1383
  xit('user should be able login to multiple accounts', async () => {
    const senderOutlook = CommonData.outlookEmail.sender;
    const subjectOutlook = CommonData.outlookEmail.subject;
    const messageOutlook = CommonData.outlookEmail.message;
    const outlookEmail = CommonData.outlookAccount.email;
    const outlookFolder = CommonData.outlookAccount.outlookFolder;

    const senderGmail = CommonData.recipientsListEmail.sender;
    const subjectGmail = CommonData.recipientsListEmail.subject;
    const messageGmail = CommonData.recipientsListEmail.message;
    const gmailFolder = CommonData.account.folder;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhraseOnLogin;

    await SplashScreen.loginToOtherEmailProvider();
    await SetupKeyScreen.setPassPhraseForOtherProviderEmail('wrong');
    await BaseScreen.checkModalMessage(wrongPassPhraseError);
    await BaseScreen.clickOkButtonOnError();
    await SetupKeyScreen.setPassPhraseForOtherProviderEmail();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailForOutlook(subjectOutlook);
    await EmailScreen.checkOpenedEmail(senderOutlook, subjectOutlook, messageOutlook);

    await EmailScreen.clickBackButton();

    await SearchScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail(outlookEmail);
    await MenuBarScreen.checkMenuBarItem(outlookFolder);

    await MenuBarScreen.clickOnUserEmail(outlookEmail);

    await MenuBarScreen.clickAddAccountButton();

    await SplashScreen.checkLoginPage();

    await SplashScreen.login();

    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailForOutlook(subjectGmail);
    await EmailScreen.checkOpenedEmail(senderGmail, subjectGmail, messageGmail);

    await EmailScreen.clickBackButton();

    await SearchScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();
    await MenuBarScreen.checkMenuBarItem(gmailFolder);

    await MenuBarScreen.clickOnUserEmail();

    await MenuBarScreen.selectAccount(1);

    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickSearchButton();

    await SearchScreen.searchAndClickEmailForOutlook(subjectOutlook);
    await EmailScreen.checkOpenedEmail(senderOutlook, subjectOutlook, messageOutlook);

    await EmailScreen.clickBackButton();

    await SearchScreen.clickBackButton();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail(outlookEmail);
    await MenuBarScreen.checkMenuBarItem(outlookFolder);
  });
});
