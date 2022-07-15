import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('COMPOSE EMAIL: ', () => {

  it('user should enter correct email address into recipients', async () => {

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com');
    mockApi.attesterConfig = {};
    mockApi.wkdConfig = {}

    const invalidRecipientError = CommonData.errors.invalidRecipient;

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient('abc');
      await BaseScreen.checkModalMessage(invalidRecipientError);
      await BaseScreen.clickOkButtonOnError();
    });
  });
});
