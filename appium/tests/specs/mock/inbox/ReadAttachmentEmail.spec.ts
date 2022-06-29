import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  AttachmentScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';

describe('INBOX: ', () => {

  it('user is able to view encrypted email with attachment', async () => {

    const senderName = CommonData.encryptedEmailWithAttachment.sender;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const attachmentName = CommonData.encryptedEmailWithAttachment.attachmentName;
    const attachmentNameWithoutExtension = attachmentName.substring(0, attachmentName.lastIndexOf('.')) || attachmentName;
    const encryptedAttachmentName = CommonData.encryptedEmailWithAttachment.encryptedAttachmentName;

    const wrongPassPhrase = 'wrong';
    const correctPassPhrase = CommonData.account.passPhrase;
    const processArgs = CommonData.mockProcessArgs;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkAttachment(encryptedAttachmentName);

      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      //try to see encrypted message with wrong pass phrase
      await EmailScreen.enterPassPhrase(wrongPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkWrongPassPhraseErrorMessage();

      //check attachment after setting correct pass phrase
      await EmailScreen.enterPassPhrase(correctPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkAttachment(encryptedAttachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await AttachmentScreen.checkAttachment(attachmentName);

      await AttachmentScreen.clickSaveButton();

      await AttachmentScreen.checkDownloadPopUp(attachmentNameWithoutExtension);
      await AttachmentScreen.clickCancelButton();
      await AttachmentScreen.checkAttachment(attachmentName);
      await AttachmentScreen.clickBackButton();

      await EmailScreen.checkAttachment(attachmentName);
      await EmailScreen.clickBackButton();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkAttachment(encryptedAttachmentName);
      await EmailScreen.clickOnAttachmentCell();

      await AttachmentScreen.checkAttachment(attachmentName);

      await AttachmentScreen.clickSaveButton();
      await AttachmentScreen.checkDownloadPopUp(attachmentNameWithoutExtension);
    });
  });
});
