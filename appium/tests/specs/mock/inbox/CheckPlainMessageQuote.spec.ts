import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('INBOX: ', () => {
  it('check plain message quote', async () => {
    const emailSubject = CommonData.plainQuoteMessage.subject;
    const emailMessage = CommonData.plainQuoteMessage.message;
    const quoteMessage = CommonData.plainQuoteMessage.quote;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['plain message quote rendering'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {},
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkInboxEmailActions();

      await EmailScreen.checkThreadMessage('sender@domain.com', emailSubject, emailMessage);
      await EmailScreen.clickToggleQuoteButton(0);
      await EmailScreen.checkQuote(0, quoteMessage);
    });
  });
});
