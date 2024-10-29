import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
  OK_BUTTON: '~aid-ok-button',
  SYSTEM_OK_BUTTON: '~Ok',
  CANCEL_BUTTON: '~aid-cancel-button',
};

class RefreshKeyScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.ENTER_YOUR_PASS_PHRASE_FIELD);
  }

  get enterPassPhraseField() {
    return $(SELECTORS.ENTER_YOUR_PASS_PHRASE_FIELD);
  }

  get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  get systemOkButton() {
    return $(SELECTORS.SYSTEM_OK_BUTTON);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BUTTON);
  }

  fillPassPhrase = async (passPhrase: string) => {
    await ElementHelper.waitClickAndType(await this.enterPassPhraseField, passPhrase);
  };

  cancelRefresh = async () => {
    await driver.dismissAlert();
  };

  clickOkButton = async () => {
    await ElementHelper.waitAndClick(await this.okButton);
  };

  clickSystemOkButton = async () => {
    await ElementHelper.waitAndClick(await this.systemOkButton);
  };
}

export default new RefreshKeyScreen();
