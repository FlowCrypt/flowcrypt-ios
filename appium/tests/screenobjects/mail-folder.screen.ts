import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  TRASH_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "TRASH"`]',
  SENT_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "SENT"`]',
  CREATE_EMAIL_BUTTON: '-ios class chain:**/XCUIElementTypeButton[`label == "+"`]',
  INBOX_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "INBOX"`]',
  SEARCH_ICON: '~search icn',
  HELP_ICON: '~help icn'
};

class MailFolderScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SEARCH_ICON);
  }

  get searchIcon() {
    return $(SELECTORS.SEARCH_ICON);
  }

  get helpIcon() {
    return $(SELECTORS.HELP_ICON);
  }

  get trashHeader() {
    return $(SELECTORS.TRASH_HEADER)
  }

  get sentHeader() {
    return $(SELECTORS.SENT_HEADER)
  }

  get inboxHeader() {
    return $(SELECTORS.INBOX_HEADER)
  }

  get createEmailButton() {
    return $(SELECTORS.CREATE_EMAIL_BUTTON);
  }

  checkTrashScreen = async () => {
    await expect(await this.trashHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  checkEmailIsNotDisplayed = async (subject: string) => {
    await (await $(`~${subject}`)).waitForDisplayed({ reverse: true });
  }

  checkSentScreen = async () => {
    await expect(await this.sentHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  refreshMailList = async () => {
    await TouchHelper.scrollUp();
  }

  clickOnEmailBySubject = async (subject: string) => {
    await browser.pause(2000); // todo: loading inbox. Fix this: wait until loader gone
    const selector = `~${subject}`;
    await ElementHelper.waitAndClick(await $(selector), 500);
  }

  clickCreateEmail = async () => {
    await browser.pause(2000); // todo: loading inbox. Fix this: wait until loader gone
    if (await (await this.createEmailButton).isDisplayed() !== true) {
      await TouchHelper.scrollDown();
      await (await this.createEmailButton).waitForDisplayed();
    }
    await ElementHelper.waitAndClick(await this.createEmailButton, 1000); // delay needed on M1
  }

  clickOnUserEmail = async (email: string) => {
    await (await this.createEmailButton).waitForDisplayed();
    await $(`~${email}`).click();
  }

  checkInboxScreen = async () => {
    await (await this.inboxHeader).waitForDisplayed();
    if (await (await this.createEmailButton).isDisplayed() !== true) {
      await TouchHelper.scrollDown();
      await (await this.createEmailButton).waitForDisplayed();
    }
  }

  scrollDown = async () => {
    await TouchHelper.scrollDown();
  }

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchIcon, 1000); // delay needed on M1
  }
}

export default new MailFolderScreen();
