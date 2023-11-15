import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  MenuBarScreen,
  EmailScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import AppiumHelper from 'tests/helpers/AppiumHelper';

describe('COMPOSE EMAIL: ', () => {
  it('sending message to user without public key produces password modal', async () => {
    const sender = CommonData.account.email;
    const recipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.recipientWithoutPublicKey.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailWeakPassword = CommonData.recipientWithoutPublicKey.weakPassword;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;

    const plainMessageModal = CommonData.recipientWithoutPublicKey.plainMessageModal;
    const emptyPasswordMessage = CommonData.recipientWithoutPublicKey.emptyPasswordMessage;
    const subjectPasswordErrorMessage = CommonData.recipientWithoutPublicKey.subjectPasswordErrorMessage;
    const addedPasswordMessage = CommonData.recipientWithoutPublicKey.addedPasswordMessage;

    const enterpriseProcessArgs = [...CommonData.mockProcessArgs, ...['--enterprise']];

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.e2e.email]: MockUserList.e2e.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // check if app shows modal for choosing between plain and password-protected message
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient],
        subject: emailSubject,
        message: emailText,
      });
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(plainMessageModal);
      await NewMessageScreen.clickCancelButton();

      await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

      await NewMessageScreen.deleteAddedRecipient(0);

      await NewMessageScreen.setAddRecipient(recipient);
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(plainMessageModal);
      await NewMessageScreen.clickCancelButton();
      await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

      // check message password validation
      await NewMessageScreen.clickPasswordCell();
      await NewMessageScreen.setMessagePassword(emailSubject);
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(subjectPasswordErrorMessage);
      await BaseScreen.clickOkButtonOnError();

      await NewMessageScreen.clickPasswordCell();
      await NewMessageScreen.setMessagePassword(emailWeakPassword);
      await NewMessageScreen.checkSetPasswordButton(false);

      await NewMessageScreen.setMessagePassword(emailPassword);
      await NewMessageScreen.checkPasswordCell(addedPasswordMessage);
      await NewMessageScreen.clickBackButton();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient, emailSubject, emailText);
      await NewMessageScreen.clickSendButton();
      await NewMessageScreen.clickSendPlainMessageButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.checkSentScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(sender, emailSubject, emailText);
      await EmailScreen.checkEncryptionBadge('not encrypted');

      // check if enterprise doesn't allow to send non-encrypted message
      await AppiumHelper.restartApp(enterpriseProcessArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient],
        subject: emailSubject,
        message: emailText,
      });
      await NewMessageScreen.clickSendButton();
      await NewMessageScreen.checkSendPlainMessageButtonNotPresent();
    });
  });
});
