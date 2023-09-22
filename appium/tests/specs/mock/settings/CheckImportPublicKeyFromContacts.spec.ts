import AddContactScreen from 'tests/screenobjects/add-contact.screen';
import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  SettingsScreen,
  MailFolderScreen,
  EmailScreen,
} from '../../../screenobjects/all-screens';
import ContactScreen from '../../../screenobjects/contacts.screen';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import BaseScreen from 'tests/screenobjects/base.screen';
import { MockUserList } from 'api-mocks/mock-data';

describe('SETTINGS: ', () => {
  it('check import public keys from contacts page', async () => {
    const mockApi = new MockApi();
    const demoKey = MockUserList.demo.pub;
    const demoEmail = MockUserList.demo.email;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {});
    mockApi.attesterConfig = {
      servedPubkeys: {},
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.clickOnAddContactButton();

      // Check if error modal displays when user tries to import invalid key
      await AddContactScreen.checkAddContactScreen();
      await AddContactScreen.importPublicKey('invalid key');
      await BaseScreen.checkModalMessage('No public keys found');
      await BaseScreen.clickOkButtonOnError();

      await AddContactScreen.importPublicKey(demoKey!);

      // Import demo public key
      await EmailScreen.importPublicKey();
      await EmailScreen.clickBackButton();
      await AddContactScreen.clickBackButton();

      await ContactScreen.checkContact(demoEmail);
    });
  });
});
