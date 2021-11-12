import BaseScreen from './base.screen';
import {CommonData} from '../data';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    SET_PASS_PHRASE_BUTTON: '~Set pass phrase',
    ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField[`value == "Enter your pass phrase"`]',
    OK_BUTTON: '~Ok',
    CONFIRM_PASS_PHRASE_FIELD: '~textField',
};

class CreateKeyScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.SET_PASS_PHRASE_BUTTON);
    }

    get setPassPhraseButton () {
        return $(SELECTORS.SET_PASS_PHRASE_BUTTON);
    }

    get enterPassPhraseField () {
        return $(SELECTORS.ENTER_YOUR_PASS_PHRASE_FIELD);
    }

    get okButton () {
        return $(SELECTORS.OK_BUTTON)
    }

    get confirmPassPhraseField () {
        return $(SELECTORS.CONFIRM_PASS_PHRASE_FIELD)
    }

    setPassPhrase(text: string = CommonData.account.passPhrase) {
        // retrying several times because following login, we switch
        //   from webview to our own view and then to another one several
        //   times, which was causing flaky tests. Originally we did a 10s
        //   delay but now instead we're retrying once per second until
        //   we see what we expect.
        let count = 0;
        do {
            browser.pause(1000);
            console.log(count);
            count++;
        } while(this.enterPassPhraseField.isDisplayed() !== true && count <= 15);
        this.fillPassPhrase(text);
        this.clickSetPassPhraseBtn();
        this.confirmPassPhrase(text);
    }

    fillPassPhrase (passPhrase: string) {
        ElementHelper.waitClickAndType(this.enterPassPhraseField, passPhrase);
    }

    clickSetPassPhraseBtn () {
        ElementHelper.waitAndClick(this.setPassPhraseButton);
    }

    confirmPassPhrase (passPhrase: string) {
        ElementHelper.waitClickAndType(this.confirmPassPhraseField, passPhrase);
        ElementHelper.waitAndClick(this.okButton);
    }
}

export default new CreateKeyScreen();
