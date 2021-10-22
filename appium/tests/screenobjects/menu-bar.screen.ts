import BaseScreen from './base.screen';
import {CommonData} from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    MENU_ICON: '~menu icn',
    LOGOUT_BTN: '~Log out',
    SETTINGS_BTN: '~Settings'
};

class MenuBarScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.MENU_ICON);
    }

    get menuIcon () {
        return $(SELECTORS.MENU_ICON);
    }

    get logoutButton () {
        return $(SELECTORS.LOGOUT_BTN);
    }

    get settingsButton () {
        return $(SELECTORS.SETTINGS_BTN)
    }

    clickMenuIcon () {
        this.menuIcon.click();
    }

    checkUserEmail (email: string = CommonData.account.email) {
        const selector = `~${email}`;
        $(selector).waitForDisplayed();
    }

    checkMenuBar () {
        expect(this.logoutButton).toBeDisplayed();
        expect(this.settingsButton).toBeDisplayed();
    }

    clickLogout () {
        this.logoutButton.click();
    }

    clickSettingsButton () {
        this.settingsButton.click();
    }
}

export default new MenuBarScreen();
