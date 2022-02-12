import { DEFAULT_TIMEOUT } from '../constants';
import ElementHelper from "../helpers/ElementHelper";


const SELECTORS = {
  ERROR_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Error"`]',
  OK_BUTTON: '~Ok',
  ERROR_FES_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Startup Error"`]',
  RETRY_BUTTON: '~Retry',
  CURRENT_MODAL: '-ios predicate string:type == "XCUIElementTypeAlert"'
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
    return $(SELECTORS.CURRENT_MODAL);
  }

  waitForScreen = async (isShown = true) => {
    await (await $(this.locator)).waitForDisplayed({
      timeout: DEFAULT_TIMEOUT,
      reverse: !isShown,
    });
  }

  static checkModalMessage = async (message: string) => {
    await expect(await this.currentModal).toBeDisplayed();
    const alertText = await driver.getAlertText();
    expect(alertText).toEqual(message);
  }

  static clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }

}
