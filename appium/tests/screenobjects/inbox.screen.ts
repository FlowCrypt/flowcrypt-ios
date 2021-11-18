import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

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
    await ElementHelper.waitAndClick(await $(`~${subject}`), 500);
  }

  clickCreateEmail = async () => {
    await ElementHelper.waitAndClick(await this.createEmailButton);
  }

  checkInboxScreen = async () => {
    await (await this.inboxHeader).waitForDisplayed();
    await (await this.createEmailButton).waitForDisplayed();
  }
}

export default new InboxScreen();
