import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  FINGERPRINT_VALUE: '~fingerprintValue',
  CREATED_VALUE: '~createdAtValue',
  EXPIRES_VALUE: '~expiresValue',
  FINGERPRINT_LABEL: '~Fingerprint:',
  CREATED_LABEL: '~Created:',
  EXPIRES_LABEL: '~Expires:',
  PGD_USER_ID_LABEL: '~User:',
  PGD_USER_ID_EMAIL: '~userEmail',
  TRASH_BUTTON: '~trash',
};

class ContactPublicKeyScreen extends BaseScreen {
  constructor() {
      super(SELECTORS.BACK_BTN);
  }

  get trashButton() {
      return $(SELECTORS.TRASH_BUTTON);
  }

  get backButton() {
      return $(SELECTORS.BACK_BTN);
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

  checkPublicKeyDetailsNotEmpty = async () => {
    await (await this.fingerPrintLabel).waitForDisplayed();
    expect(await (await this.fingerPrintValue).getAttribute('value')).toBeTruthy();
    await (await this.createdLabel).waitForDisplayed();
    expect(await (await this.createdValue).getAttribute('value')).toBeTruthy();
    await (await this.expiresLabel).waitForDisplayed();
    expect(await (await this.expiresValue).getAttribute('value')).toBeTruthy();
  }

  checkPublicKeyDetailsNotDisplayed = async () => {
    await ElementHelper.waitElementInvisible(await this.fingerPrintLabel);
    await ElementHelper.waitElementInvisible(await this.fingerPrintValue);
    await ElementHelper.waitElementInvisible(await this.createdLabel);
    await ElementHelper.waitElementInvisible(await this.createdValue);
    await ElementHelper.waitElementInvisible(await this.expiresLabel);
    await ElementHelper.waitElementInvisible(await this.expiresValue);
  }

  checkPgpUserId = async (email: string) => {
    await (await this.trashButton).waitForDisplayed();
    await (await this.pgpUserIdLabel).waitForDisplayed();
    expect(await (await this.pgpUserIdEmailValue).getAttribute('value')).toContain(email);
  }

  clickOnFingerPrint = async () => {
    await ElementHelper.waitAndClick(await this.fingerPrintValue);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickTrashButton = async () => {
    await ElementHelper.waitAndClick(await this.trashButton);
  }
}

export default new ContactPublicKeyScreen();
