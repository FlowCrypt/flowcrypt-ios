import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  FINGERPRINT_VALUE: '~aid-fingerprint-value',
  CREATED_VALUE: '~aid-created-at-value',
  EXPIRES_VALUE: '~aid-expires-value',
  FINGERPRINT_LABEL: '~aid-fingerprint-label',
  CREATED_LABEL: '~aid-created-at-label',
  EXPIRES_LABEL: '~aid-expires-label',
  PGD_USER_ID_LABEL: '~aid-user-label',
  PGD_USER_ID_EMAIL: '~aid-user-email',
  TRASH_BUTTON: '~aid-trash-button',
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
  };

  checkPublicKeyDetailsNotDisplayed = async () => {
    await ElementHelper.waitElementInvisible(await this.fingerPrintLabel);
    await ElementHelper.waitElementInvisible(await this.fingerPrintValue);
    await ElementHelper.waitElementInvisible(await this.createdLabel);
    await ElementHelper.waitElementInvisible(await this.createdValue);
    await ElementHelper.waitElementInvisible(await this.expiresLabel);
    await ElementHelper.waitElementInvisible(await this.expiresValue);
  };

  checkPgpUserId = async (email: string, name?: string) => {
    const value = name ? `${name} <${email}>` : email;
    await (await this.trashButton).waitForDisplayed();
    await (await this.pgpUserIdLabel).waitForDisplayed();
    expect(await (await this.pgpUserIdEmailValue).getAttribute('value')).toContain(value);
  };

  clickOnFingerPrint = async () => {
    await ElementHelper.waitAndClick(await this.fingerPrintValue);
  };

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  };

  clickTrashButton = async () => {
    await ElementHelper.waitAndClick(await this.trashButton);
  };
}

export default new ContactPublicKeyScreen();
