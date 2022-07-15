import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app and text autoscroll', async () => {
    const recipient = MockUserList.dmitry;
    const ccRecipient = MockUserList.demo;
    const bccRecipient = MockUserList.robot;

    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const longEmailText = CommonData.longEmail.message;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [
        MockUserList.dmitry, MockUserList.demo, MockUserList.robot
      ]
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.dmitry.email]: MockUserList.dmitry.pub!,
        [MockUserList.demo.email]: MockUserList.demo.pub!,
        [MockUserList.robot.email]: MockUserList.robot.pub!
      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setComposeSecurityMessage(longEmailText);
      await NewMessageScreen.checkRecipientsTextFieldIsInvisible();

      await NewMessageScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient.email, emailSubject, emailText, ccRecipient.email, bccRecipient.email);

      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient.name],
        subject: emailSubject,
        message: emailText,
        cc: [ccRecipient.name],
        bcc: [bccRecipient.name]
      });

      await driver.background(3);

      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient.name],
        subject: emailSubject,
        message: emailText,
        cc: [ccRecipient.name],
        bcc: [bccRecipient.name]
      });
    });
  });
});
