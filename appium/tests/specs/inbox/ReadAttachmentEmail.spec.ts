import {
  SplashScreen,
  SetupKeyScreen,
  InboxScreen,
  EmailScreen,
  AttachmentScreen
} from '../../screenobjects/all-screens';

import { CommonData } from '../../data';

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
    await InboxScreen.checkInboxScreen();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName); //disabled due to

    await driver.terminateApp(bundleId);
    await driver.activateApp(bundleId);

    await InboxScreen.clickOnEmailBySubject(emailSubject);

    //try to see encrypted message with wrong pass phrase
    await EmailScreen.enterPassPhrase(wrongPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkWrongPassPhraseErrorMessage();

    //check attachment after setting correct pass phrase
    await EmailScreen.enterPassPhrase(correctPassPhrase);
    await EmailScreen.clickOkButton();
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickOnDownloadButton();

    await AttachmentScreen.checkDownloadPopUp(attachmentName);
    await AttachmentScreen.clickOnCancelButton();

    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickBackButton();

    await InboxScreen.clickOnEmailBySubject(emailSubject);
    await EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
    await EmailScreen.checkAttachment(attachmentName);
    await EmailScreen.clickOnDownloadButton();

    await AttachmentScreen.checkDownloadPopUp(attachmentName);
  });
});
