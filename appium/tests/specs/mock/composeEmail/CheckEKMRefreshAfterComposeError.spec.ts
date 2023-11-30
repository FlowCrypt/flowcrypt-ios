import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';
import { CommonData } from 'tests/data';
import BaseScreen from 'tests/screenobjects/base.screen';

describe('COMPOSE EMAIL: ', () => {
  it('check handling of invalid keys on message compose', async () => {
    const mockApi = new MockApi();

    const recipient = MockUserList.robot;
    const subject = 'check revoked key after from ekm';
    const message = 'check revoked key after from ekm';
    const noPrivateKeyError = CommonData.errors.noPrivateKey;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eRevokedKey.prv],
    };
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com');
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      // Stage1: Try to compose message with revoked encryption key
      await NewMessageScreen.composeEmail(recipient.email, subject, message);
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(noPrivateKeyError);
      await BaseScreen.clickOkButtonOnError();

      // Now update ekm to return valid key and check if message is sent correctly
      mockApi.ekmConfig = {
        returnKeys: [ekmKeySamples.e2e.prv],
      };
      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkInboxScreen();
    });
  });
});
