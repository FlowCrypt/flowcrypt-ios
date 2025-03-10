import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { SplashScreen } from '../../../screenobjects/all-screens';
import MailFolderScreen from '../../../screenobjects/mail-folder.screen';
import NewMessageScreen from '../../../screenobjects/new-message.screen';
import SetupKeyScreen from '../../../screenobjects/setup-key.screen';
import { CommonData } from 'tests/data';

describe('SETUP: ', () => {
  it('check password message compliance', async () => {
    const mockApi = new MockApi();
    const disallowedPasswordMessageErrorText =
      'Password-protected messages are disabled. Please check https://test.com';
    const emailPassword = CommonData.recipientWithoutPublicKey.password;

    mockApi.fesConfig = {
      clientConfiguration: {
        ...MockApiConfig.defaultEnterpriseFesConfiguration.clientConfiguration,
        disallow_password_messages_for_terms: ['forbidden', 'test'],
        disallow_password_messages_error_text: disallowedPasswordMessageErrorText,
      },
    };
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {},
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail('test@gmail.com', 'forbidden subject', 'test message');
      await NewMessageScreen.clickSendButton();

      await NewMessageScreen.clickSendMessagePasswordButton();
      await NewMessageScreen.setMessagePassword(emailPassword);
      await NewMessageScreen.clickSendButton();

      await NewMessageScreen.checkCustomAlertMessage(disallowedPasswordMessageErrorText);
    });
  });
});
