import BaseScreen from './base.screen';

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  PUBLIC_KEY_HEADER: '~aid-navigation-item-public-key',
  PUBLIC_KEY: '~aid-public-key-node',
};

class PublicKeyScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN);
  }

  get publicKey() {
    return $(SELECTORS.PUBLIC_KEY);
  }

  get publicKeyHeader() {
    return $(SELECTORS.PUBLIC_KEY_HEADER);
  }

  getPublicKeyValue = async () => {
    await (await this.backButton).waitForDisplayed();
    await (await this.publicKeyHeader).waitForDisplayed();
    const publicKeyEl = await this.publicKey;
    await publicKeyEl.waitForExist();
    return await publicKeyEl.getAttribute('value');
  }

  checkPublicKey = async () => {
    await this.checkPublicKeyContains('-----BEGIN PGP PUBLIC KEY BLOCK-----');
  }

  checkPublicKeyContains = async (text: string) => {
    const pubkeyValue = await this.getPublicKeyValue();
    expect(pubkeyValue.includes(text)).toBeTruthy();
  }

  checkPublicKeyNotContains = async (text: string) => {
    const pubkeyValue = await this.getPublicKeyValue();
    expect(pubkeyValue.includes(text)).toBeFalsy();
  }

  clickBackButton = async () => {
    await this.backButton.click();
  }
}

export default new PublicKeyScreen();
