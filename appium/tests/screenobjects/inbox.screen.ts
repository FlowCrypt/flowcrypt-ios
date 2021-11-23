import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import TouchHelper from "../helpers/TouchHelper";

const SELECTORS = {
  ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField[`value == "Enter your pass phrase"`]',
  OK_BUTTON: '~Ok',
  CONFIRM_PASS_PHRASE_FIELD: '~textField',
  CREATE_EMAIL_BUTTON: '-ios class chain:**/XCUIElementTypeButton[`label == "+"`]',
  INBOX_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "INBOX"`]'
};

class InboxScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.CONFIRM_PASS_PHRASE_FIELD);
  }

  get createEmailButton() {
    return $(SELECTORS.CREATE_EMAIL_BUTTON);
  }

  get inboxHeader() {
    return $(SELECTORS.INBOX_HEADER)
  }

  clickOnUserEmail = async (email: string) => {
    await (await this.createEmailButton).waitForDisplayed();
    await $(`~${email}`).click();
  }

  clickOnEmailBySubject = async (subject: string) => {
    const selector =  `~${subject}`;
    if (await (await $(selector)).isDisplayed() !== true) {
      await TouchHelper.scrollDown();
    }
    await ElementHelper.waitAndClick(await $(selector), 500);
  }

  clickCreateEmail = async () => {
    if (await (await this.createEmailButton).isDisplayed() !== true ) {
      await TouchHelper.scrollDown();
      await (await this.createEmailButton).waitForDisplayed();
    }
    await ElementHelper.waitAndClick(await this.createEmailButton);
  }

  checkInboxScreen = async () => {
    await (await this.inboxHeader).waitForDisplayed();
      if (await (await this.createEmailButton).isDisplayed() !== true) {
        await TouchHelper.scrollDown();
        await (await this.createEmailButton).waitForDisplayed();
      }
  }
}

export default new InboxScreen();
