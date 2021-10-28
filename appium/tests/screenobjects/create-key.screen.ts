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
        try {
            this.fillPassPhrase(text);
        } catch {
            console.log(driver.getPageSource());
        }
        this.clickSetPassPhraseBtn();
        this.confirmPassPhrase(text);
    }

    fillPassPhrase (passPhrase: string) {
        ElementHelper.clickAndType(this.enterPassPhraseField, passPhrase);
    }

    clickSetPassPhraseBtn () {
        ElementHelper.waitAndClick(this.setPassPhraseButton);
    }

    confirmPassPhrase (passPhrase: string) {
        ElementHelper.clickAndType(this.confirmPassPhraseField, passPhrase);
        ElementHelper.waitAndClick(this.okButton);
    }
}

export default new CreateKeyScreen();
