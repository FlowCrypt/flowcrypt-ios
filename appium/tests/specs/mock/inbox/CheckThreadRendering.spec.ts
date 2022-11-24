import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  MenuBarScreen
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('INBOX: ', () => {

  it('check thread rendering and archived message actions', async () => {
    const senderName = CommonData.threadMessage.senderName;
    const emailSubject = CommonData.threadMessage.subject;
    const firstMessage = CommonData.threadMessage.firstThreadMessage;
    const secondMessage = CommonData.threadMessage.secondThreadMessage;
    const thirdMessage = CommonData.threadMessage.thirdThreadMessage;
    const thirdMessageQuote = CommonData.threadMessage.thirdThreadMessageQuote;
    const userEmail = CommonData.account.email;
    const dateFirst = CommonData.threadMessage.firstDate;
    const dateSecond = CommonData.threadMessage.secondDate;
    const dateThird = CommonData.threadMessage.thirdDate;
    const archivedThreadSubject = CommonData.archivedThread.subject;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['test thread rendering', 'Archived thread'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.dmitry.email]: MockUserList.dmitry.pub!,
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkInboxEmailActions();

      await EmailScreen.checkThreadMessage(senderName, emailSubject, thirdMessage, 2, dateThird);
      await EmailScreen.checkThreadMessage(userEmail, emailSubject, secondMessage, 1, dateSecond);
      await EmailScreen.checkThreadMessage(senderName, emailSubject, firstMessage, 0, dateFirst);

      await EmailScreen.checkQuoteIsHidden(2);
      await EmailScreen.clickToggleQuoteButton(2);
      await EmailScreen.checkQuote(2, thirdMessageQuote);

      await EmailScreen.clickBackButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickAllMailButton();
      await MailFolderScreen.clickOnEmailBySubject(archivedThreadSubject);
      await EmailScreen.checkArchivedEmailActions();
    });
  });
});
