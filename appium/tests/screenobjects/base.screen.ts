import { DEFAULT_TIMEOUT } from '../constants';
import ElementHelper from "../helpers/ElementHelper";


const SELECTORS = {
  ERROR_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Error"`]',
  OK_BUTTON: '~OK',
  ERROR_FES_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Startup Error"`]',
  RETRY_BUTTON: '~Retry',
  CURRENT_ERROR: '-ios predicate string:type == "XCUIElementTypeAlert"'
};

export default class BaseScreen {

  locator: string;
  constructor(selector: string) {
    this.locator = selector;
  }

  static get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  static get currentModal() {
    return $(SELECTORS.CURRENT_ERROR);
  }

  waitForScreen = async (isShown = true) => {
    await (await $(this.locator)).waitForDisplayed({
      timeout: DEFAULT_TIMEOUT,
      reverse: !isShown,
    });
  }

  static checkErrorModal = async (errorText: string) => {
    await expect(await this.currentModal).toBeDisplayed();
    const alertText = await driver.getAlertText();
    await expect(alertText).toEqual(errorText);
  }

  static clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }

}
