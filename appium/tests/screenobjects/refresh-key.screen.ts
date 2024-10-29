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
    try {
      await ElementHelper.waitAndClick(await this.cancelButton);
    } catch {
      // For some reason clicking cancel button with aid-cancel-button identifier doesn't work. Try to click with click text identifier
      // https://flowcrypt.semaphoreci.com/jobs/fdde00a1-33b1-4df9-a9b8-49d546c2ef79/summary?report_id=4ae71336-e44b-39bf-b9d2-752e234818a5&test_id=8e5e69c0-6bc7-316b-ab4d-7b75d419353e
      await ElementHelper.waitAndClick(await $('~Cancel'));
    }
  };

  clickOkButton = async () => {
    await ElementHelper.waitAndClick(await this.okButton);
  };

  clickSystemOkButton = async () => {
    await ElementHelper.waitAndClick(await this.systemOkButton);
  };
}

export default new RefreshKeyScreen();
