import BaseScreen from './base.screen';

const SELECTORS = {
    BACK_BTN: '~arrow left c'
};

const { join } = require('path');

class EmailScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.BACK_BTN);
    }

    get backButton() {
        return $(SELECTORS.BACK_BTN)
    }

    checkEmailAddress (email) {
        const selector = `~${email}`;
        $(selector).waitForDisplayed();
    }

    checkEmailSubject (subject) {
        const selector = `~${subject}`;
        $(selector).waitForDisplayed();
    }

    checkEmailText (text) {
        const selector = `~${text}`;
        $(selector).waitForDisplayed();
    }

    checkOpenedEmail (email, subject, text) {
        this.backButton.waitForDisplayed();
        this.checkEmailAddress(email);
        this.checkEmailSubject(subject);
        this.checkEmailText(text);
    }

    clickBackButton () {
        this.backButton.click();
    }
}

export default new EmailScreen();
