import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    BACK_BTN: '~arrow left c',
    KEY: '~Key',
    PUBLIC_KEY: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[2]',
    FINGERPRINT_VALUE: '-ios class chain:**/XCUIElementTypeCell[2]/XCUIElementTypeOther/XCUIElementTypeStaticText[2]',
    CREATED_VALUE: '-ios class chain:**/XCUIElementTypeCell[2]/XCUIElementTypeOther/XCUIElementTypeStaticText[4]',
    EXPIRES_VALUE: '-ios class chain:**/XCUIElementTypeCell[2]/XCUIElementTypeOther/XCUIElementTypeStaticText[6]',
    FINGERPRINT_LABEL: '~Fingerprint:',
    CREATED_LABEL: '~Created:',
    EXPIRES_LABEL: '~Expires:',
    PGD_USER_ID_LABEL: '~User:',
    PGD_USER_ID_EMAIL: '-ios class chain:**/XCUIElementTypeCell[1]/XCUIElementTypeOther/XCUIElementTypeStaticText[2]',
    TRASH_BUTTON: '~trash'
};

class ContactPublicKeyScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.BACK_BTN);
    }

    get trashButton () {
        return $(SELECTORS.TRASH_BUTTON);
    }

    get backButton() {
        return $(SELECTORS.BACK_BTN);
    }

    get key() {
        return $(SELECTORS.KEY);
    }

    get publicKey() {
        return $(SELECTORS.PUBLIC_KEY);
    }

    get fingerPrintLabel() {
        return $(SELECTORS.FINGERPRINT_LABEL);
    }

    get fingerPrintValue() {
        return $(SELECTORS.FINGERPRINT_VALUE);
    }

    get createdLabel() {
        return $(SELECTORS.CREATED_LABEL);
    }

    get createdValue() {
        return $(SELECTORS.CREATED_VALUE);
    }

    get expiresLabel() {
        return $(SELECTORS.EXPIRES_LABEL);
    }

    get expiresValue() {
        return $(SELECTORS.EXPIRES_VALUE);
    }

    get pgpUserIdLabel() {
        return $(SELECTORS.PGD_USER_ID_LABEL);
    }

    get pgpUserIdEmailValue() {
        return $(SELECTORS.PGD_USER_ID_EMAIL);
    }

    checkPublicKeyNotEmpty() {
        this.backButton.waitForDisplayed();
        this.key.waitForDisplayed();
        this.publicKey.waitForExist();
        expect(this.publicKey.getAttribute('value')).not.toEqual(null);
    }

    checkPublicKeyDetailsNotEmpty () {
        this.backButton.waitForDisplayed();
        this.fingerPrintLabel.waitForDisplayed();
        expect(this.fingerPrintValue.getAttribute('value')).not.toEqual(null);
        this.createdLabel.waitForDisplayed();
        expect(this.createdValue.getAttribute('value')).not.toEqual(null);
        this.expiresLabel.waitForDisplayed();
        expect(this.expiresValue.getAttribute('value')).not.toEqual(null);
    }

    checkPgpUserId(email) {
        this.trashButton.waitForDisplayed();
        this.pgpUserIdLabel.waitForDisplayed();
        expect(this.pgpUserIdEmailValue.getAttribute('value')).toContain(email);
    }

    clickOnFingerPrint() {
        ElementHelper.waitAndClick(this.fingerPrintValue);
    }

}

export default new ContactPublicKeyScreen();
