import { DEFAULT_TIMEOUT } from '../constants';
import ElementHelper from "../helpers/ElementHelper";


const SELECTORS = {
  OK_BUTTON: '~Ok',
  CANCEL_BUTTON: '~aid-cancel-button',
  CONFIRM_BUTTON: '~aid-confirm-button',
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

  static get cancelButton() {
    return $(SELECTORS.CANCEL_BUTTON);
  }

  static get confirmButton() {
    return $(SELECTORS.CONFIRM_BUTTON);
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
    await ElementHelper.waitElementVisible(await this.currentModal);
    const alertText = await driver.getAlertText();
    expect(alertText).toContain(message);
  }

  static checkToastMessage = async (message: string) => {
    await ElementHelper.waitElementVisible(await $(`~${message}`));
  }

  static clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }

  static clickConfirmButton = async () => {
    await ElementHelper.waitAndClick(await this.confirmButton)
  }

  static clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton)
  }

}
