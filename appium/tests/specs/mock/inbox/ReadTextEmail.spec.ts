import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from "../../../../api-mocks/mock";

describe('COMPOSE EMAIL: ', () => {

  it('check filled compose email after reopening app and text autoscroll', async () => {

    const senderName = CommonData.recipientsListEmail.senderName;
    const emailSubject = CommonData.recipientsListEmail.subject;
    const emailText = CommonData.recipientsListEmail.message;
    const recipientsButton = CommonData.recipientsListEmail.recipients;
    const toLabel = CommonData.recipientsListEmail.to;
    const ccLabel = CommonData.recipientsListEmail.cc;
    const bccLabel = CommonData.recipientsListEmail.bcc;

    const mockApi = new MockApi();

    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickSearchButton();
      await SearchScreen.searchAndClickEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkRecipientsButton(recipientsButton);
      await EmailScreen.clickRecipientsButton();
      await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
    });
  });
});
