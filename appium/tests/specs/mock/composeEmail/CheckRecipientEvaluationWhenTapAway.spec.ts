import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check recipient evaluation when user taps outside the search area', async () => {
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.checkRecipientEvaluationWhenTapOutside();
    });
  });
});
