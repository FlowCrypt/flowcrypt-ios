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
    USER_LABEL: '~User:',
    USER_EMAIL: '-ios class chain:**/XCUIElementTypeCell[1]/XCUIElementTypeOther/XCUIElementTypeStaticText[2]',
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

    get fingerPrint() {
        return $(SELECTORS.FINGERPRINT_LABEL);
    }

    get fingerPrintValue() {
        return $(SELECTORS.FINGERPRINT_VALUE);
    }

    get created() {
        return $(SELECTORS.CREATED_LABEL);
    }

    get createdValue() {
        return $(SELECTORS.CREATED_VALUE);
    }

    get expires() {
        return $(SELECTORS.EXPIRES_LABEL);
    }

    get expiresValue() {
        return $(SELECTORS.EXPIRES_VALUE);
    }

    get user() {
        return $(SELECTORS.USER_LABEL);
    }

    get userEmail() {
        return $(SELECTORS.USER_EMAIL);
    }

    checkPublicKey() {
        this.backButton.waitForDisplayed();
        this.key.waitForDisplayed();
        this.publicKey.waitForExist();
        expect(this.publicKey.getAttribute('value')).not.toEqual(null);
    }

    checkContactPublicKey () {
        this.backButton.waitForDisplayed();
        this.fingerPrint.waitForDisplayed();
        expect(this.fingerPrintValue.getAttribute('value')).not.toEqual(null);
        this.created.waitForDisplayed();
        expect(this.createdValue.getAttribute('value')).not.toEqual(null);
        this.expires.waitForDisplayed();
        expect(this.expiresValue.getAttribute('value')).not.toEqual(null);
    }

    checkUser(email) {
        this.trashButton.waitForDisplayed();
        this.user.waitForDisplayed();
        expect(this.userEmail.getAttribute('value')).toContain(email);
    }

    clickOnFingerPrint() {
        ElementHelper.waitAndClick(this.fingerPrint);
    }

}

export default new ContactPublicKeyScreen();
