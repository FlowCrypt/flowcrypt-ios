import {
  MailFolderScreen,
  MenuBarScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import TouchHelper from 'tests/helpers/TouchHelper';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('should toggle recipient list label and show correct email addresses', async () => {

    const recipient = MockUserList.robot;
    const ccRecipient = MockUserList.expired;
    const bccRecipientEmail = CommonData.recipientWithoutPublicKey.email;
    const subject = "Test recipient list label subject"
    const message = "Test recipient list label message"

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [recipient, ccRecipient],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
        [ccRecipient.email]: ccRecipient.pub!
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Check current user email
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();
      await TouchHelper.tapScreen('centerRight');

      // Add first contact
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient.email, subject, message, ccRecipient.email, bccRecipientEmail);
      await NewMessageScreen.checkRecipientLabel([recipient.name, ccRecipient.name, bccRecipientEmail]);
    });
  });
});
