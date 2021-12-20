import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  AttachmentScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('INBOX: ', () => {

  it('user is able to view encrypted email with attachment', async () => {

    const senderEmail = CommonData.sender.email;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const attachmentName = CommonData.encryptedEmailWithAttachment.attachmentName;

    const wrongPassPhrase = 'wrong';
    const correctPassPhrase = CommonData.account.passPhrase;
    const bundleId = CommonData.bundleId.id;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.searchEmailBySubject(emailSubject);
    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName);

    await driver.terminateApp(bundleId);
    await driver.activateApp(bundleId);

    await MailFolderScreen.checkInboxScreen();
    await MailFolderScreen.searchEmailBySubject(emailSubject);
    await MailFolderScreen.clickOnEmailBySubject(emailSubject);

    //try to see encrypted message with wrong pass phrase
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkWrongPassPhraseErrorMessage();

    //check attachment after setting correct pass phrase
    await EmailScreen.enterPassPhrase(correctPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickOnAttachmentCell();
    await AttachmentScreen.checkAttachment(attachmentName);

    await AttachmentScreen.clickSaveButton();

    await AttachmentScreen.checkDownloadPopUp(attachmentName);
    await AttachmentScreen.clickCancelButton();
    await AttachmentScreen.checkAttachment(attachmentName);
    await AttachmentScreen.clickBackButton();

    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickBackButton();

    await MailFolderScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickOnAttachmentCell();

    await AttachmentScreen.checkAttachment(attachmentName);

    await AttachmentScreen.clickSaveButton();
    await AttachmentScreen.checkDownloadPopUp(attachmentName);
  });
});
