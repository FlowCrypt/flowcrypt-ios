import { DEFAULT_TIMEOUT } from '../constants';
import ElementHelper from "../helpers/ElementHelper";


const SELECTORS = {
  ERROR_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Error"`]',
  OK_BUTTON: '~OK'
};

export default class BaseScreen {

  locator: string;
  constructor(selector: string) {
    this.locator = selector;
  }

  static get errorHeader() {
    return $(SELECTORS.ERROR_HEADER)
  }

  static get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  waitForScreen = async (isShown = true) => {
    await (await $(this.locator)).waitForDisplayed({
      timeout: DEFAULT_TIMEOUT,
      reverse: !isShown,
    });
  }

  static checkErrorModal = async (errorText: string) => {
    const message = '-ios class chain:**/XCUIElementTypeAlert/XCUIElementTypeOther/XCUIElementTypeOther/' +
      'XCUIElementTypeOther[2]/XCUIElementTypeScrollView[1]/XCUIElementTypeOther[1]/XCUIElementTypeStaticText[2]';//it works only with this selector
    await expect(await this.errorHeader).toBeDisplayed();
    await expect(await $(message)).toHaveAttribute('value', `${errorText}`);
    await expect(await this.okButton).toBeDisplayed();
  }

  static clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }

}
