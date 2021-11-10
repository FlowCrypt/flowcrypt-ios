import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    CANCEL_BTN: '~Cancel',
};

class AttachmentScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.CANCEL_BTN);
    }

    get cancelButton() {
        return $(SELECTORS.CANCEL_BTN);
    }

    checkDownloadPopUp(name) {
        this.cancelButton.waitForDisplayed();
        const attachment = `-ios class chain:**/XCUIElementTypeNavigationBar[\`name == "com_apple_DocumentManager_Service.DOCServiceTargetSelectionBrowserView"\`]/XCUIElementTypeButton/XCUIElementTypeStaticText`;//it works only with this selector
        expect($(attachment)).toHaveAttribute('value', `${name}`);
    }

    clickOnCancelButton() {
        ElementHelper.waitAndClick(this.cancelButton);
    }
}

export default new AttachmentScreen();
