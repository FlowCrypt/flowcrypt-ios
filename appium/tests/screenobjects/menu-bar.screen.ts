import BaseScreen from './base.screen';
import {CommonData} from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    MENU_ICON: '~menu icn',
    LOGOUT_BTN: '~Log out',
    SETTINGS_BTN: '~Settings',
    DRAFT_BUTTON: '~Draft',
    INBOX_BTN: '~Inbox'
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
        return $(SELECTORS.SETTINGS_BTN);
    }

    get inboxButton () {
        return $(SELECTORS.INBOX_BTN);
    }

    get draftButton () {
        return $(SELECTORS.DRAFT_BUTTON)
    }

    clickMenuIcon () {
        ElementHelper.waitAndClick(this.menuIcon);
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
        ElementHelper.waitAndClick(this.logoutButton);
    }

    clickSettingsButton () {
        ElementHelper.waitAndClick(this.settingsButton);
    }

    clickDraftButton () {
        ElementHelper.waitAndClick(this.draftButton);
    }

    clickInboxButton () {
        ElementHelper.waitAndClick(this.inboxButton);
    }
}

export default new MenuBarScreen();
