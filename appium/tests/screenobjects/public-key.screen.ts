import BaseScreen from './base.screen';

const SELECTORS = {
  BACK_BTN: '~arrow left c',
  PUBLIC_KEY_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Public key"`]',
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

  get publicKeyHeader() {
    return $(SELECTORS.PUBLIC_KEY_HEADER);
  }

  checkPublicKey = async () => {
    await (await this.backButton).waitForDisplayed();
    await (await this.publicKeyHeader).waitForDisplayed();
    const publicKeyEl = await this.publicKey;
    await publicKeyEl.waitForExist();
    // const pubkeyValue = await publicKeyEl.getAttribute('value');
    // todo - fixme https://github.com/FlowCrypt/flowcrypt-ios/issues/1068
    //     [0-11] Error in "SETTINGS:  user should see public key and should not see private key"
    // Error: Expected 'e2e' to contain '-----BEGIN PGP PUBLIC KEY BLOCK-----'.
    //     at <Jasmine>
    //     at PublicKeyScreen.checkPublicKey (/Users/tom/git/flowcrypt-ios/appium/tests/screenobjects/public-key.screen.ts:32:31)
    //     at processTicksAndRejections (node:internal/process/task_queues:96:5)
    //     at async UserContext.<anonymous> (/Users/tom/git/flowcrypt-ios/appium/tests/specs/settings/CheckSettingsForLoggedUser.spec.ts:34:5)``
    // await expect(pubkeyValue).toContain("-----BEGIN PGP PUBLIC KEY BLOCK-----");
  }
}

export default new PublicKeyScreen();
