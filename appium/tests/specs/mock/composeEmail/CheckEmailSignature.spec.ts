import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { SplashScreen } from '../../../screenobjects/all-screens';
import MailFolderScreen from '../../../screenobjects/mail-folder.screen';
import NewMessageScreen from '../../../screenobjects/new-message.screen';
import SetupKeyScreen from '../../../screenobjects/setup-key.screen';

describe('SETUP: ', () => {
  it('check if signature is added correctly', async () => {
    const mockApi = new MockApi();

    const aliasEmail = 'test@gmail.com';
    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      signature: 'Test primary signature',
      aliases: [
        {
          sendAsEmail: aliasEmail,
          displayName: 'Demo Alias',
          replyToAddress: aliasEmail,
          signature: 'Test alias signature',
          isDefault: false,
          isPrimary: false,
          treatAsAlias: false,
          verificationStatus: 'accepted',
        },
      ],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.checkComposeMessageText('Test primary signature');

      // Change alias and check if signature changes correctly
      await NewMessageScreen.changeFromEmail(aliasEmail);
      await NewMessageScreen.checkComposeMessageText('Test alias signature');
    });
  });
});
