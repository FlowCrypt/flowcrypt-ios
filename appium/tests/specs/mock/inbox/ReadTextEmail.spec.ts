import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from "../../../../api-mocks/mock";

describe('INBOX: ', () => {

  it('user is able to view text email and recipients list', async () => {

    const senderName = CommonData.recipientsListEmail.senderName;
    const emailSubject = CommonData.recipientsListEmail.subject;
    const emailText = CommonData.recipientsListEmail.message;
    const recipientsButton = CommonData.recipientsListEmail.recipients;
    const toLabel = CommonData.recipientsListEmail.to;
    const ccLabel = CommonData.recipientsListEmail.cc;
    const bccLabel = CommonData.recipientsListEmail.bcc;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkRecipientsButton(recipientsButton);
      await EmailScreen.clickRecipientsButton();
      await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
    });
  });
});
