import BaseScreen from './base.screen';

const SELECTORS = {
  BACK_BTN: '~arrow left c',
  PUBLIC_KEY: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[1]',
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

  checkPublicKey = async () => {
    await (await this.backButton).waitForDisplayed();
    const publicKeyEl = await this.publicKey;
    await publicKeyEl.waitForExist();
    const pubkeyValue = await publicKeyEl.getAttribute('value');
    expect(pubkeyValue).toBeExisting();
  }
}

export default new PublicKeyScreen();
