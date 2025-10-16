import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import {
  SplashScreen,
  MailFolderScreen,
  NewMessageScreen,
  SetupKeyScreen,
  MenuBarScreen,
  EmailScreen,
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {
  it('check public key attachment attach', async () => {
    const mockApi = new MockApi();
    const recipient = MockUserList.dmitry;
    const testSubject1 = 'Test public key attachment - PGP';
    const testSubject2 = 'Test public key attachment - Password';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    const email = 'e2e.enterprise.test@flowcrypt.com';
    mockApi.addGoogleAccount(email);

    // Set up attester to serve public key for PGP recipient
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Test 1: Public key attachment with regular PGP message
      await MailFolderScreen.clickCreateEmail();

      // Compose email
      await NewMessageScreen.setAddRecipient(recipient.email);
      await NewMessageScreen.setSubject(testSubject1);
      await NewMessageScreen.setComposeSecurityMessage('This message includes my public key');

      // Click attach button
      await NewMessageScreen.clickAttachButton();

      // Wait for action sheet to appear and click "Public key" using accessibility identifier
      await browser.pause(1000);
      await NewMessageScreen.clickAttachPublicKeyButton();

      // Check that public key attachment was added
      // The filename should be in format 0x{longid}.asc
      await browser.pause(1000);
      const attachmentLabel = await NewMessageScreen.attachmentNameLabel;
      const attachmentName = await attachmentLabel.getValue();
      expect(attachmentName).toMatch(/^0x[A-F0-9]{16}\.asc$/);

      // Send the message
      await NewMessageScreen.clickSendButton();
      await browser.pause(1000);

      // Go to sent folder to verify the attachment
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.checkSentScreen();
      await MailFolderScreen.clickOnEmailBySubject(testSubject1);

      // Verify attachment in sent email
      // TODO: need to uncomment this line when we fix public key render issue
      // https://github.com/FlowCrypt/flowcrypt-ios/issues/634
      // await EmailScreen.checkPublicKeyImportView(email, recipient.pub!, false);
      await EmailScreen.clickBackButton();

      // Go back to inbox for test 2
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.checkInboxScreen();

      // Test 2: Public key attachment with password-protected message (non-PGP recipient)
      await MailFolderScreen.clickCreateEmail();

      // Compose email to non-PGP recipient
      await NewMessageScreen.setAddRecipient('non-pgp@example.com');
      await NewMessageScreen.setSubject(testSubject2);
      await NewMessageScreen.setComposeSecurityMessage('This password-protected message includes my public key');

      // Click attach button
      await NewMessageScreen.clickAttachButton();

      // Wait for action sheet to appear and click "Public key" using accessibility identifier
      await browser.pause(1000);
      await NewMessageScreen.clickAttachPublicKeyButton();

      // Check that public key attachment was added
      await browser.pause(1000);
      const attachmentLabel2 = await NewMessageScreen.attachmentNameLabel;
      const attachmentName2 = await attachmentLabel2.getValue();
      expect(attachmentName2).toMatch(/^0x[A-F0-9]{16}\.asc$/);

      // Set message password
      await NewMessageScreen.clickPasswordCell();
      await NewMessageScreen.setMessagePassword('abcABC1*');

      // Send the password-protected message
      await NewMessageScreen.clickSendButton();
      await browser.pause(1000);

      // Go to sent folder to verify the attachment
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.checkSentScreen();
      await MailFolderScreen.clickOnEmailBySubject(testSubject2);

      // Verify attachment in sent password-protected email
      // TODO: need to uncomment this line when we fix public key render issue
      // https://github.com/FlowCrypt/flowcrypt-ios/issues/634
      // await EmailScreen.checkPublicKeyImportView(email, recipient.pub!, false);
    });
  });
});
