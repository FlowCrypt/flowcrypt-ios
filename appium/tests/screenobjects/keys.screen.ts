import BaseScreen from './base.screen';

const SELECTORS = {
    KEYS_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Keys"`]',
    ADD_BUTTON: '~Add',
    NAME_AND_EMAIL: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[1]',
    DATE_CREATED: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[2]',
    FINGERPRINT: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[3]',
    SHOW_PUBLIC_KEY_BUTTON: '~Show public key',
    SHOW_KEY_DETAILS_BUTTON: '~Show key details',
    COPY_TO_CLIPBOARD_BUTTON: '~Copy to clipboard',
    SHARE_BUTTON: '~Share',
    SHOW_PRIVATE_KEY_BUTTON: '~Show private key'
};

class KeysScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.KEYS_HEADER);
    }

    get keysHeader() {
        return $(SELECTORS.KEYS_HEADER);
    }

    get addButton() {
        return $(SELECTORS.ADD_BUTTON);
    }

    get nameAndEmail() {
        return $(SELECTORS.NAME_AND_EMAIL);
    }

    get dateCreated() {
        return $(SELECTORS.DATE_CREATED);
    }

    get fingerPrint() {
        return $(SELECTORS.FINGERPRINT);
    }

    get showPublicKeyButton() {
        return $(SELECTORS.SHOW_PUBLIC_KEY_BUTTON);
    }

    get showPrivateKeyButton() {
        return $(SELECTORS.SHOW_PRIVATE_KEY_BUTTON);
    }

    get showKeyDetailsButton() {
        return $(SELECTORS.SHOW_KEY_DETAILS_BUTTON);
    }

    get shareButton() {
        return $(SELECTORS.SHARE_BUTTON);
    }

    get copiToClipboardButton() {
        return $(SELECTORS.COPY_TO_CLIPBOARD_BUTTON);
    }

    checkKeysScreen() {
        //will add value verification for key later, need to create Api request for get key value
        this.keysHeader.waitForDisplayed();
        //this.addButton.waitForDisplayed({reverse: true}); -  disabled due to https://github.com/FlowCrypt/flowcrypt-ios/issues/715
        this.nameAndEmail.waitForExist();
        this.dateCreated.waitForExist();
        this.fingerPrint.waitForExist();
        expect(this.nameAndEmail.getAttribute('value')).not.toEqual(null);
        expect(this.dateCreated.getAttribute('value')).not.toEqual(null);
        expect(this.fingerPrint.getAttribute('value')).not.toEqual(null);
    }

    clickOnKey() {
        this.nameAndEmail.click();
    }

    checkSelectedKeyScreen() {
        this.showPublicKeyButton.waitForDisplayed();
        this.showPrivateKeyButton.waitForDisplayed();
        this.showKeyDetailsButton.waitForDisplayed();
        this.shareButton.waitForDisplayed();
        this.copiToClipboardButton.waitForDisplayed();
    }

    clickOnShowPublicKey() {
        this.showPublicKeyButton.click();
    }
}

export default new KeysScreen();
