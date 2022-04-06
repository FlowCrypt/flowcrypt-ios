import {
  MailFolderScreen,
  MenuBarScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('should toggle recipient list label and show correct email addresses ', async () => {

    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const ccRecipientEmail = CommonData.recipientWithExpiredPublicKey.email;
    const ccRecipientName = CommonData.recipientWithExpiredPublicKey.name;
    const bccRecipientEmail = CommonData.recipientWithoutPublicKey.email;
    const subject = "Test recipient list label subject"
    const message = "Test recipient list label message"

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    // Add first contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientEmail, subject, message, ccRecipientEmail, bccRecipientEmail);
    await NewMessageScreen.checkRecipientLabel([recipientName, ccRecipientName, bccRecipientEmail]);

  });
});
