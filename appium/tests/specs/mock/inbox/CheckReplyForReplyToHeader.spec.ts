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

describe('INBOX: ', () => {

  it('should honor reply-to address when reply-to header is present', async () => {

    const senderEmail = CommonData.honorReplyTo.sender;
    const emailSubject = CommonData.honorReplyTo.subject;
    const replySubject = `Re: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n >`;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Honor reply-to address - plain'],
    });
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      // check reply message
      await EmailScreen.clickReplyButton();
      await NewMessageScreen.showRecipientLabelIfNeeded();
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [CommonData.honorReplyTo.replyToEmail],
        subject: replySubject,
        message: quoteText
      });
    });
  });
});
