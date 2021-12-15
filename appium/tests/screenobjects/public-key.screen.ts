import BaseScreen from './base.screen';

const SELECTORS = {
  BACK_BTN: '~aid-back-icon',
  PUBLIC_KEY_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Public key"`]',
  PUBLIC_KEY: '~publicKey',
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
}

export default new PublicKeyScreen();
