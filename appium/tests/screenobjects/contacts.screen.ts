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

    contactEmail(email) {
        return $(`~${email}`)
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

    checkContact(email) {
        this.contactEmail(email).waitForDisplayed();
    }

    clickOnContact(email) {
        ElementHelper.waitAndClick(this.contactEmail(email));
    }
}

export default new ContactsScreen();
