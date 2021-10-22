import BaseScreen from './base.screen';
import {CommonData} from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    BACK_BTN: '~arrow left c',
    PUBLIC_KEY: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[1]',
};

class PublicKeyScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.BACK_BTN);
    }

    get backButton() {
        return $(SELECTORS.BACK_BTN);
    }

    get publicKey() {
        return $(SELECTORS.PUBLIC_KEY);
    }

    checkPublicKey() {
        this.backButton.waitForDisplayed();
        this.publicKey.waitForDisplayed();
        expect(this.publicKey).not.toHaveAttribute('value', null);
    }
}

export default new PublicKeyScreen();
