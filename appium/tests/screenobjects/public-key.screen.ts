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

  checkPublicKey = async () => {
    await (await this.backButton).waitForDisplayed();
    await (await this.publicKeyHeader).waitForDisplayed();
    const publicKeyEl = await this.publicKey;
    await publicKeyEl.waitForExist();
    const pubkeyValue = await publicKeyEl.getAttribute('value');
    await expect(pubkeyValue).toContain("-----BEGIN PGP PUBLIC KEY BLOCK-----");
  }

  clickBackButton = async () => {
    await this.backButton.click();
  }
}

export default new PublicKeyScreen();
