import BaseScreen from './base.screen';

const SELECTORS = {
    ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField[`value == "Enter your pass phrase"`]',
    OK_BUTTON: '~Ok',
    CONFIRM_PASS_PHRASE_FIELD: '~textField',
    CREATE_EMAIL_BUTTON: '-ios class chain:**/XCUIElementTypeButton[`label == "+"`]',
};

class InboxScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.CONFIRM_PASS_PHRASE_FIELD);
    }

    get createEmailButton () {
        return $(SELECTORS.CREATE_EMAIL_BUTTON);
    }

    clickOnUserEmail (email) {
        this.createEmailButton.waitForDisplayed();
        const selector = `~${email}`;
        $(selector).click();
    }

    clickOnEmailBySubject (subject) {
        this.createEmailButton.waitForDisplayed();
        const selector = `~${subject}`;
        $(selector).click();
    }

    clickCreateEmail () {
        this.createEmailButton.click();
    }
}

export default new InboxScreen();
