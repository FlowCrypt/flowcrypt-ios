import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

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
    return $(SELECTORS.CANCEL_BTN)
  }

  checkDownloadPopUp = async (name: string) => {
    await (await this.cancelButton).waitForDisplayed();
    const attachment = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "com_apple_DocumentManager_Service.DOCServiceTargetSelectionBrowserView"\`]/XCUIElementTypeButton/XCUIElementTypeStaticText`;//it works only with this selector
    expect(await $(attachment)).toHaveAttribute('value', `${name}`);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  }

  checkAttachment = async (name: string) => {
    await (await this.backButton).waitForDisplayed();
    const attachmentHeader = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "${name}"\`]`;
    expect(await $(attachmentHeader)).toBeDisplayed();
    await (await this.saveButton).waitForDisplayed();
  }

  clickSaveButton = async () => {
    await ElementHelper.waitAndClick(await this.saveButton);
  }
}

export default new AttachmentScreen();
