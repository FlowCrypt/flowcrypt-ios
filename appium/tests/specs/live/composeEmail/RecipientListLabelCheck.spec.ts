import {
  MailFolderScreen,
  MenuBarScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

import {CommonData} from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('should toggle recipient list label and show correct email addresses ', async () => {

    let recipientEmail = CommonData.recipient.email;
    let ccRecipientEmail = CommonData.recipientWithExpiredPublicKey.email;
    let bccRecipientEmail = CommonData.recipientWithoutPublicKey.email;
    let subject = "Test recipient list label subject"
    let message= "Test recipient list label message"

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    // Go to Contacts screen
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    // Add first contact
    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.composeEmail(recipientEmail, subject, message, ccRecipientEmail, bccRecipientEmail);
    await NewMessageScreen.checkRecipientLabel([recipientEmail, ccRecipientEmail, bccRecipientEmail]);

  });
});
