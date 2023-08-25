import { MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {
  it('check sending password protected message bcc leakage', async () => {
    const recipient = CommonData.recipientWithoutPublicKey.email;
    const emailSubject = CommonData.recipientWithoutPublicKey.subject;
    const emailText = CommonData.simpleEmail.message;
    const emailPassword = CommonData.recipientWithoutPublicKey.password;
    const bcc = 'test@example.com';

    const mockApi = new MockApi();

    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.fesConfig = {
      ...MockApiConfig.defaultEnterpriseFesConfiguration,
      messageUploadCheck: {
        to: [recipient],
        cc: [],
        bcc: [],
      },
    };
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
      await NewMessageScreen.composeEmail(recipient, emailSubject, emailText, undefined, bcc);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient],
        subject: emailSubject,
        message: emailText,
        bcc: [bcc],
      });
      await NewMessageScreen.clickPasswordCell();
      await NewMessageScreen.setMessagePassword(emailPassword);
      await NewMessageScreen.clickSendButton();
    });
  });
});
