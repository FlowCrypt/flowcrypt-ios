import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('INBOX: ', () => {

  it('test for replying to my own email and changing recipient', async () => {

    const senderEmail = CommonData.emailForReplyWithChangingRecipient.senderEmail;
    const emailSubject = CommonData.emailForReplyWithChangingRecipient.subject;
    const secondMessage = CommonData.emailForReplyWithChangingRecipient.secondMessage;
    const newRecipientEmail = CommonData.emailForReplyWithChangingRecipient.newRecipientEmail;
    const newRecipientName = CommonData.emailForReplyWithChangingRecipient.newRecipientName;
    const firstRecipientName = CommonData.emailForReplyWithChangingRecipient.firstRecipientName;
    const secondRecipientName = CommonData.emailForReplyWithChangingRecipient.secondRecipientName;
    const thirdRecipientName = CommonData.emailForReplyWithChangingRecipient.thirdRecipientName;

    const replySubject = `Re: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n > ${secondMessage}`;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [],
          messages: [
            'new message for reply'
          ],
        }
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {

      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkThreadMessage(senderEmail, emailSubject, secondMessage, 1);

      // check reply message
      await EmailScreen.clickReplyButton();
      await browser.pause(500);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [firstRecipientName, secondRecipientName],
        subject: replySubject,
        message: quoteText
      });
      await NewMessageScreen.deleteAddedRecipientWithDoubleBackspace();
      await NewMessageScreen.setAddRecipient(newRecipientEmail);

      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [firstRecipientName, newRecipientName],
        subject: replySubject,
        message: quoteText
      });

      await NewMessageScreen.clickBackButton();
      await EmailScreen.checkThreadMessage(senderEmail, emailSubject, secondMessage, 1);
      await EmailScreen.clickMenuButton();
      await EmailScreen.clickReplyAllButton();

      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [firstRecipientName, secondRecipientName],
        cc: [thirdRecipientName],
        subject: replySubject,
        message: quoteText
      });

      await NewMessageScreen.deleteAddedRecipientWithDoubleBackspace();
      await NewMessageScreen.setAddRecipientByName('Ioan', newRecipientEmail);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [firstRecipientName, newRecipientName],
        cc: [thirdRecipientName],
        subject: replySubject,
        message: quoteText
      });
      await NewMessageScreen.clickBackButton();
      await EmailScreen.checkThreadMessage(senderEmail, emailSubject, secondMessage, 1);
    });
  });
});
