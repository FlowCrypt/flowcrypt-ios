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

describe('COMPOSE EMAIL: ', () => {

  it('should toggle recipient list label and show correct email addresses', async () => {

    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const ccRecipientEmail = CommonData.recipientWithExpiredPublicKey.email;
    const ccRecipientName = CommonData.recipientWithExpiredPublicKey.name;
    const bccRecipientEmail = CommonData.recipientWithoutPublicKey.email;
    const subject = "Test recipient list label subject"
    const message = "Test recipient list label message"

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Check current user email
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();
      await TouchHelper.tapScreen('centerRight');

      // Add first contact
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipientEmail, subject, message, ccRecipientEmail, bccRecipientEmail);
      await NewMessageScreen.checkRecipientLabel([recipientName, ccRecipientName, bccRecipientEmail]);
    });
  });
});
