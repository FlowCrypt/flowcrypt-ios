import BaseScreen from './base.screen';

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
        this.menuIcon.click()
    }

    checkUserEmail (email) {
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
}

export default new MenuBarScreen();
