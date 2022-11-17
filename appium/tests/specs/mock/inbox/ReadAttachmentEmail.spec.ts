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
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('INBOX: ', () => {

  it('user is able to view encrypted email with attachment', async () => {

    const senderName = CommonData.encryptedEmailWithAttachment.senderName;
    const emailSubject = CommonData.encryptedEmailWithAttachment.subject;
    const emailText = CommonData.encryptedEmailWithAttachment.message;
    const attachmentName = CommonData.encryptedEmailWithAttachment.attachmentName;
    const attachmentNameWithoutExtension = attachmentName.substring(0, attachmentName.lastIndexOf('.'));
    const encryptedAttachmentName = CommonData.encryptedEmailWithAttachment.encryptedAttachmentName;

    const messageWithoutPreviewSender = CommonData.encryptedEmailWithAttachmentWithoutPreview.sender;
    const messageWithoutPreviewSubject = CommonData.encryptedEmailWithAttachmentWithoutPreview.subject;
    const attachmentWithoutPreviewName = CommonData.encryptedEmailWithAttachmentWithoutPreview.attachmentName;
    const attachmentWithoutPreviewNameWithoutExtension = attachmentWithoutPreviewName.substring(0, attachmentWithoutPreviewName.lastIndexOf('.'));

    const wrongPassPhrase = 'wrong';
    const correctPassPhrase = CommonData.account.passPhrase;
    const processArgs = CommonData.mockProcessArgs;

    const mockApi = new MockApi();
    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Message with cc and multiple recipients and text attachment', 'message with kdbx file'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.dmitry.email]: MockUserList.dmitry.pub!,
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkAttachment(encryptedAttachmentName);

      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      // try to see encrypted message with wrong pass phrase
      await EmailScreen.enterPassPhrase(wrongPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkWrongPassPhraseErrorMessage();

      // check attachment after setting correct pass phrase
      await EmailScreen.enterPassPhrase(correctPassPhrase);
      await EmailScreen.clickOkButton();
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkAttachment(encryptedAttachmentName);
      await EmailScreen.clickOnAttachmentCell();
      await AttachmentScreen.checkAttachment(attachmentName);

      await AttachmentScreen.clickSaveButton();

      await AttachmentScreen.checkDownloadPopUp(attachmentNameWithoutExtension);
      await AttachmentScreen.clickSystemBackButton();
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
      await AttachmentScreen.clickSystemBackButton();
      await AttachmentScreen.clickCancelButton();
      await AttachmentScreen.clickBackButton();
      await EmailScreen.clickBackButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(messageWithoutPreviewSubject);
      await EmailScreen.checkOpenedEmail(messageWithoutPreviewSender, messageWithoutPreviewSubject, '');
      await EmailScreen.checkAttachment(attachmentWithoutPreviewName);
      await EmailScreen.clickOnAttachmentCell();
      await AttachmentScreen.checkDownloadPopUp(attachmentWithoutPreviewNameWithoutExtension);
    });
  });
});
