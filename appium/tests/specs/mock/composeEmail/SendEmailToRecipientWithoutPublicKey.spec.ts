import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user without public key produces password modal', async () => {

    const recipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.recipientWithoutPublicKey.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailWeakPassword = CommonData.recipientWithoutPublicKey.weakPassword;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;

    const passwordModalMessage = CommonData.recipientWithoutPublicKey.modalMessage;
    const emptyPasswordMessage = CommonData.recipientWithoutPublicKey.emptyPasswordMessage;
    const subjectPasswordErrorMessage = CommonData.recipientWithoutPublicKey.subjectPasswordErrorMessage;
    const addedPasswordMessage = CommonData.recipientWithoutPublicKey.addedPasswordMessage;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(passwordModalMessage);
      await NewMessageScreen.clickCancelButton();
      await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

      await NewMessageScreen.deleteAddedRecipient(0);

      await NewMessageScreen.setAddRecipient(recipient);
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(passwordModalMessage);
      await NewMessageScreen.clickCancelButton();
      await NewMessageScreen.checkPasswordCell(emptyPasswordMessage);

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
    });
  });
});
