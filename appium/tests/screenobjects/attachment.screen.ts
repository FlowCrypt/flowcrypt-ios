import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
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

  get saveButton() {
    return $(SELECTORS.SAVE_BTN);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BTN);
  }

  checkDownloadPopUp = async (name: string) => {
    const attachmentTextField = $('-ios class chain:**/XCUIElementTypeTextField'); // textfield from system file dialog
    await ElementHelper.waitElementVisible(await attachmentTextField);
    expect(await attachmentTextField.getValue()).toEqual(name);
  };

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  };

  clickSystemBackButton = async () => {
    // Due to a issue in SemaphoreCI environment, a single back button click does not yield the expected behavior.
    // Therefore, we have implemented a mechanism to continuously click the system back button until cancel button appears.
    await browser.pause(1000);
    let systemBackButton = await $('~Back');
    if (!(await systemBackButton.isDisplayed())) {
      const browseButton = await $('~Browse'); // Back button is renamed to Browse in newer iOS versions
      if (await browseButton.isDisplayed()) {
        systemBackButton = browseButton;
      } else {
        throw new Error('System backup button is not displayed either using Back or Browse selector');
      }
    }
    await ElementHelper.clickUntilExpectedElementAppears(systemBackButton, await this.cancelButton, 10);
  };

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  };

  checkAttachment = async (name: string) => {
    const attachmentHeader = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "${name}"\`]`;

    await ElementHelper.waitElementVisible(await this.backButton);
    await ElementHelper.waitElementVisible(await $(attachmentHeader));
    await ElementHelper.waitElementVisible(await this.saveButton);
  };

  clickSaveButton = async () => {
    await ElementHelper.waitAndClick(await this.saveButton);
  };
}

export default new AttachmentScreen();
