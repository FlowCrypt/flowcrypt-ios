import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
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

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Keys');

    await KeysScreen.checkKeysScreen([ekmKeySamples.demoUser, ekmKeySamples.e2e, ekmKeySamples.flowcryptCompability]);
    await KeysScreen.clickOnKey();

    await KeysScreen.checkSelectedKeyScreen();

    await KeysScreen.clickOnShowPublicKey();
    await PublicKeyScreen.checkPublicKey();
  });
});
