import BaseScreen from './base.screen';
import commonData from '../data/index';

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

    fillPassPhrase (passPhrase: string) {
        this.enterPassPhraseField.setValue(passPhrase);
    }

    clickSetPassPhraseBtn () {
        this.setPassPhraseButton.click();
    }

    confirmPassPhrase (passPhrase: string) {
        this.confirmPassPhraseField.click();
        this.confirmPassPhraseField.setValue(passPhrase);
        this.okButton.click();
    }

    setPassPhrase(text: string = commonData.account.passPhrase) {
        this.fillPassPhrase(text);
        this.clickSetPassPhraseBtn();
        this.confirmPassPhrase(text);
    }
}

export default new CreateKeyScreen();
