import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
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
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.key1.prv, ekmKeySamples.e2e.prv]
    }
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          aliases: [{
            sendAsEmail: aliasEmail,
            displayName: 'Demo Alias',
            replyToAddress: aliasEmail,
            signature: '',
            isDefault: false,
            isPrimary: false,
            treatAsAlias: false,
            verificationStatus: 'accepted'
          }],
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

    await mockApi.withMockedApis(async () => {
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
