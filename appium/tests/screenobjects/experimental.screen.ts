import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  EXPERIMENTAL_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Experimental"`]',
  BACK_BUTTON: '~aid-back-button',
  RELOAD_APP_BUTTON: '~Reload app',
};

class ExperimentalScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.EXPERIMENTAL_HEADER);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON);
  }

  get reloadAppButton() {
    return $(SELECTORS.RELOAD_APP_BUTTON);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton, 1000);
  }

  clickReloadAppButton = async () => {
    await ElementHelper.waitAndClick(await this.reloadAppButton, 1000);
  }

}

export default new ExperimentalScreen();
