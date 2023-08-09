import { SplashScreen, SetupKeyScreen, MailFolderScreen } from '../../../screenobjects/all-screens';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import PublicKeyHelper from 'tests/helpers/PublicKeyHelper';

describe('SETTINGS: ', () => {
  it('check updating keys from wkd', async () => {
    const recipient = MockUserList.demo;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [recipient],
    });
    mockApi.wkdConfig = {
      servedPubkeys: {
        demo: recipient.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      // stage 1: load recipient and check contact
      await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(recipient.email, true, {
        recipientName: recipient.name,
        expiryDate: 'Aug 14, 2023',
      });
      // stage 2: updated WKD to return newer version of the key and check if it's updated correctly
      mockApi.wkdConfig = {
        servedPubkeys: {
          demo: recipient.pubNew!,
        },
      };
      await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(recipient.email, true, {
        recipientName: recipient.name,
        expiryDate: 'Aug 6, 2024',
      });
      // stage 3: updated WKD to return 1 more key(this key doesn't expire) and check if it's added correctly
      mockApi.wkdConfig = {
        servedPubkeys: {
          demo: recipient.pubOther!,
        },
      };
      await PublicKeyHelper.loadRecipientInComposeThenCheckKeyDetails(recipient.email, false, {
        recipientName: recipient.name,
        expiryDate: '-',
        publicKeyCount: 2,
      });
    });
  });
});
