import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    CONTACTS_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Contacts"`]',
    BACK_BUTTON: '~arrow left c',
    EMPTY_CONTACTS_LIST: '~Empty list',
};

class ContactsScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.CONTACTS_HEADER);
    }

    get contactsHeader() {
        return $(SELECTORS.CONTACTS_HEADER);
    }

    get backButton() {
        return $(SELECTORS.BACK_BUTTON);
    }

    get emptyContactsList() {
        return $(SELECTORS.EMPTY_CONTACTS_LIST);
    }

    contactName(name) {
        return $(`~${name}`)
    }

    checkContactScreen() {
        this.contactsHeader.waitForDisplayed();
        this.backButton.waitForDisplayed();
    }

    checkEmptyList() {
        this.emptyContactsList.waitForDisplayed();
    }

    clickBackButton () {
        ElementHelper.waitAndClick(this.backButton);
    }

    checkContact(name) {
        this.contactName(name).waitForDisplayed();
    }

    clickOnContact(name) {
        ElementHelper.waitAndClick(this.contactName(name));
    }
}

export default new ContactsScreen();
