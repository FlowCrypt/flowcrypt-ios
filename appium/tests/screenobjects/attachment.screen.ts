import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  SYSTEM_BACK_BTN: '~Back',
  SAVE_BTN: '~aid-save-attachment-to-device',
  CANCEL_BTN: '~Cancel', // can't change aid for UIDocumentPickerViewController 
};

class AttachmentScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN);
  }

  get systemBackButton() {
    return $(SELECTORS.SYSTEM_BACK_BTN);
  }

  get saveButton() {
    return $(SELECTORS.SAVE_BTN);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BTN)
  }

  checkDownloadPopUp = async (name: string) => {
    const attachmentTextField = $('-ios class chain:**/XCUIElementTypeTextField'); // textfield from system file dialog
    await ElementHelper.waitElementVisible(await attachmentTextField);
    expect(await attachmentTextField.getValue()).toEqual(name);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickSystemBackButton = async (delay: number) => {
    await browser.pause(delay);
    await driver.back();
    const systemBackButton = await this.systemBackButton;
    // Added this logic because clicking `Back` button doesn't work in semaphoreCI
    if (await systemBackButton.isDisplayed()) {
      await ElementHelper.waitAndClick(systemBackButton);
    }
  }

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  }

  checkAttachment = async (name: string) => {
    const attachmentHeader = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "${name}"\`]`;

    await ElementHelper.waitElementVisible(await this.backButton);
    await ElementHelper.waitElementVisible(await $(attachmentHeader));
    await ElementHelper.waitElementVisible(await this.saveButton);
  }

  clickSaveButton = async () => {
    await ElementHelper.waitAndClick(await this.saveButton);
  }
}

export default new AttachmentScreen();
