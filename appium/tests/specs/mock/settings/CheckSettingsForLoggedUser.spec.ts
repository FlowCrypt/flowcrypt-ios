import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  SettingsScreen,
  KeysScreen,
  PublicKeyScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';

describe('SETTINGS: ', () => {

  it('user should see public key and should not see private key', async () => {

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Keys');

      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.e2e, ekmKeySamples.key1]);
      await KeysScreen.clickOnKey();

      await KeysScreen.checkSelectedKeyScreen();

      await KeysScreen.clickOnShowPublicKey();
      await PublicKeyScreen.checkPublicKey();
    });
  });
});
