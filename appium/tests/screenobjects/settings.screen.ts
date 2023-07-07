import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';
const SELECTORS = {
  MENU_ICON: '~aid-menu-button',
};

class SettingsScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.MENU_ICON);
  }

  settingsItem = async (setting: string) => {
    return await $(`~${setting}`);
  };

  checkSettingsScreen = async () => {
    await (await this.settingsItem('Security and Privacy')).waitForDisplayed();
    await (await this.settingsItem('Contacts')).waitForDisplayed();
    await (await this.settingsItem('Keys')).waitForDisplayed();
    await (await this.settingsItem('Attester')).waitForDisplayed();
    await (await this.settingsItem('Notifications')).waitForDisplayed();
    await (await this.settingsItem('Legal')).waitForDisplayed();
    await (await this.settingsItem('Experimental')).waitForDisplayed();
    await (await this.settingsItem('Backups')).waitForDisplayed({ reverse: true });
  };

  clickOnSettingItem = async (item: string) => {
    await ElementHelper.waitAndClick(await this.settingsItem(item));
  };
}

export default new SettingsScreen();
