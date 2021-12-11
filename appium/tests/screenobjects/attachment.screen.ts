import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BTN: '~arrow left c'
};

class AttachmentScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN);
  }

  checkDownloadPopUp = async (name: string) => {
    await (await this.backButton).waitForDisplayed();
    const attachment = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "com_apple_DocumentManager_Service.DOCServiceTargetSelectionBrowserView"\`]/XCUIElementTypeButton/XCUIElementTypeStaticText`;//it works only with this selector
    expect(await $(attachment)).toHaveAttribute('value', `${name}`);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }
}

export default new AttachmentScreen();
