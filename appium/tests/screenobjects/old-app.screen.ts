import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

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
  SHOW_PRIVATE_KEY_BUTTON: '~Show private key',
  BACK_BUTTON: '~aid-back-button',
};

class OldAppScreen extends BaseScreen {
  constructor() {
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

  get copyToClipboardButton() {
    return $(SELECTORS.COPY_TO_CLIPBOARD_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON)
  }

  checkKeysScreen = async () => {
    //will add value verification for key later, need to create Api request for get key value
    await (await this.keysHeader).waitForDisplayed();
    await (await this.addButton).waitForDisplayed({ reverse: true });
    await (await this.nameAndEmail).waitForExist();
    await (await this.dateCreated).waitForExist();
    await (await this.fingerPrint).waitForExist();
    expect(await (await this.nameAndEmail).getAttribute('value')).toBeTruthy();
    expect(await (await this.dateCreated).getAttribute('value')).toBeTruthy();
    expect(await (await this.fingerPrint).getAttribute('value')).toBeTruthy();
  }

  clickOnKey = async () => {
    await ElementHelper.waitAndClick(await this.nameAndEmail);
  }

  checkSelectedKeyScreen = async () => {
    await (await this.showPublicKeyButton).waitForDisplayed();
    await (await this.showPrivateKeyButton).waitForDisplayed({ reverse: true });
    await (await this.showKeyDetailsButton).waitForDisplayed();
    await (await this.shareButton).waitForDisplayed();
    await (await this.copyToClipboardButton).waitForDisplayed();
  }

  clickOnShowPublicKey = async () => {
    await ElementHelper.waitAndClick(await this.showPublicKeyButton);
  }

  clickBackButton = async () => {
    await this.backButton.click();
  }
}

export default new OldAppScreen();
