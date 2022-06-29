import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';

describe('INBOX: ', () => {

  it('should honor reply-to address when reply-to header is present', async () => {

    const senderEmail = CommonData.honorReplyTo.sender;
    const emailSubject = CommonData.honorReplyTo.subject;
    const replySubject = `Re: ${emailSubject}`;
    const quoteText = `${senderEmail} wrote:\n >`;

    await MockApi.e2eMock.withMockedApis(async () => {
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
