import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
const SELECTORS = {
    MENU_ICON: '~menu icn',
};

class SettingsScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.MENU_ICON);
    }

    settingsItem (setting) {
        return $(`~${setting}`);
    }

    checkSettingsScreen() {
        this.settingsItem('Security and Privacy').waitForDisplayed();
        this.settingsItem('Contacts').waitForDisplayed();
        this.settingsItem('Keys').waitForDisplayed();
        this.settingsItem('Attester').waitForDisplayed();
        this.settingsItem('Notifications').waitForDisplayed();
        this.settingsItem('Legal').waitForDisplayed();
        this.settingsItem('Experimental').waitForDisplayed();
        this.settingsItem('Backups').waitForDisplayed({reverse: true});
    }

    clickOnSettingItem(item) {
        ElementHelper.waitAndClick(this.settingsItem(item));
    }
}

export default new SettingsScreen();
