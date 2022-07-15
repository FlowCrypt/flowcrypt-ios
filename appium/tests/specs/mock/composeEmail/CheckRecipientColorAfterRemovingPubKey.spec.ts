import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SettingsScreen,
  MenuBarScreen,
  PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';

import PublicKeyHelper from "../../../helpers/PublicKeyHelper";
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('check recipient color after removing public key from settings', async () => {
    const mockApi = new MockApi();
    const contact = MockUserList.dmitry;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [contact],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [contact.email]: contact.pub!
      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await PublicKeyHelper.addRecipientAndCheckFetchedKey(contact.name, contact.email);

      await PublicKeyDetailsScreen.clickTrashButton();
      await ContactPublicKeyScreen.checkPgpUserId(contact.email, contact.name);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotDisplayed();
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactWithoutPubKey(contact.email);
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.checkInboxScreen();

      await PublicKeyHelper.addRecipientAndCheckFetchedKey(contact.name, contact.email);
    });
  });
});
