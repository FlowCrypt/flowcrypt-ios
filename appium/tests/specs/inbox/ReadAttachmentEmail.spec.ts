import {
    SplashScreen,
    CreateKeyScreen,
    InboxScreen,
    EmailScreen,
    AttachmentScreen
} from '../../screenobjects/all-screens';

import {CommonData} from '../../data';

describe('INBOX: ', () => {

    it('user is able to view encrypted email with attachment', () => {

        const senderEmail = CommonData.sender.email;
        const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
        const emailText = CommonData.encryptedEmailWithAttachment.message;
        const attachmentName = CommonData.encryptedEmailWithAttachment.attachmentName;

        const wrongPassPhrase = 'wrong';
        const correctPassPhrase = CommonData.account.passPhrase;
        const bundleId = CommonData.bundleId.id;

        SplashScreen.login();
        CreateKeyScreen.setPassPhrase();

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
        EmailScreen.checkAttachment(attachmentName); //disabled due to

        driver.terminateApp(bundleId);

        driver.activateApp(bundleId);

        InboxScreen.clickOnEmailBySubject(emailSubject);

        //try to see encrypted message with wrong pass phrase
        EmailScreen.enterPassPhrase(wrongPassPhrase);
        EmailScreen.clickOkButton();
        EmailScreen.checkWrongPassPhraseErrorMessage();

        //check attachment after setting correct pass phrase
        EmailScreen.enterPassPhrase(correctPassPhrase);
        EmailScreen.clickSaveButton();
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
        EmailScreen.checkAttachment(attachmentName);
        EmailScreen.clickOnDownloadButton();

        AttachmentScreen.checkDownloadPopUp(attachmentName);
        AttachmentScreen.clickOnCancelButton();

        EmailScreen.checkAttachment(attachmentName);
        EmailScreen.clickBackButton();

        InboxScreen.clickOnEmailBySubject(emailSubject);
        EmailScreen.checkOpenedEmail(senderEmail, emailSubject, emailText);
        EmailScreen.checkAttachment(attachmentName);
        EmailScreen.clickOnDownloadButton();

        AttachmentScreen.checkDownloadPopUp(attachmentName);
    });
});
