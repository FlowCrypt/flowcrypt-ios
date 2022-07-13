import { MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('check added recipient popup', async () => {
    const recipient1 = MockUserList.dmitry;
    const recipient2 = MockUserList.expired;
    const recipient3 = MockUserList.revoked;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [recipient1, recipient2, recipient3],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient(recipient1.email);
      await NewMessageScreen.setAddRecipient(recipient2.email);
      await NewMessageScreen.setAddRecipient(recipient3.email);

      await NewMessageScreen.checkPopupRecipientInfo(recipient1.email, 0, 'to', recipient1.name);
      await NewMessageScreen.checkPopupRecipientInfo(recipient2.email, 1, 'to', recipient2.name);
      await NewMessageScreen.checkPopupRecipientInfo(recipient3.email, 2, 'to', recipient3.name);

      await NewMessageScreen.checkCopyForAddedRecipient(recipient1.email, 0);

      await NewMessageScreen.checkEditRecipient(0, 'to', recipient1.name, 3);

      await NewMessageScreen.deleteAddedRecipient(2);
      await NewMessageScreen.deleteAddedRecipientWithBackspace(1);
      await NewMessageScreen.deleteAddedRecipient(0);
    });
  });
});
