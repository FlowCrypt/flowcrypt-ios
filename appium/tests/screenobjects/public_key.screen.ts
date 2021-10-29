import BaseScreen from './base.screen';

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
        this.publicKey.waitForExist();
        expect(this.publicKey.getAttribute('value')).not.toEqual(null);
    }
}

export default new PublicKeyScreen();
