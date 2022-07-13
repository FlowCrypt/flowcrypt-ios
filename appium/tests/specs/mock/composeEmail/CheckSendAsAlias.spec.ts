import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { CommonData } from 'tests/data';
import {
  MailFolderScreen, NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('user should be able to send email with alias', async () => {

    const recipient = MockUserList.robot;
    const emailSubject = CommonData.alias.subject;
    const aliasEmail = CommonData.alias.email;
    const emailText = CommonData.alias.message;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [recipient],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
      }
    };
    mockApi.wkdConfig = {}

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.composeEmail(recipient.email, emailSubject, emailText);
      await NewMessageScreen.checkRecipientLabel([recipient.name]);
      await NewMessageScreen.changeFromEmail(aliasEmail);

      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkInboxScreen();
    });
  });
});
