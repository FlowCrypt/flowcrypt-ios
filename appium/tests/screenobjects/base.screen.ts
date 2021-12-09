import { DEFAULT_TIMEOUT } from '../constants';
import ElementHelper from "../helpers/ElementHelper";


const SELECTORS = {
  ERROR_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Error"`]',
  OK_BUTTON: '~OK',
  ERROR_FES_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Startup Error"`]',
  RETRY_BUTTON: '~Retry'
};

export default class BaseScreen {

  locator: string;
  constructor(selector: string) {
    this.locator = selector;
  }

  static get errorHeader() {
    return $(SELECTORS.ERROR_HEADER)
  }

  static get errorFESHeader() {
    return $(SELECTORS.ERROR_FES_HEADER)
  }

  static get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  static get retryButton() {
    return $(SELECTORS.RETRY_BUTTON)
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
    expect(await (await $(message)).getAttribute('value')).toContain(errorText);
    await expect(await this.okButton).toBeDisplayed();
  }

  static checkErrorModalForFES = async (errorText: string) => {
    const message = '-ios class chain:**/XCUIElementTypeAlert/XCUIElementTypeOther/XCUIElementTypeOther/' +
        'XCUIElementTypeOther[2]/XCUIElementTypeScrollView[1]/XCUIElementTypeOther[1]/XCUIElementTypeStaticText[2]';//it works only with this selector
    await expect(await this.errorFESHeader).toBeDisplayed();
    expect(await (await $(message)).getAttribute('value')).toContain(errorText);
    await expect(await this.retryButton).toBeDisplayed();
  }

  static clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }

}
