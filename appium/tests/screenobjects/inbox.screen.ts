import BaseScreen from './base.screen';

const SELECTORS = {
    ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField[`value == "Enter your pass phrase"`]',
    OK_BUTTON: '~Ok',
    CONFIRM_PASS_PHRASE_FIELD: '~textField',

};

class InboxScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.CONFIRM_PASS_PHRASE_FIELD);
    }
    clickOnUserEmail (email) {
        const selector = `~${email}`;
        $(selector).click();
    }


}

export default new InboxScreen();
