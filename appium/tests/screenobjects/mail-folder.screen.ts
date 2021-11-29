import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  TRASH_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "TRASH"`]',
  SENT_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "SENT"`]',
  CREATE_EMAIL_BUTTON: '-ios class chain:**/XCUIElementTypeButton[`label == "+"`]',
  INBOX_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "INBOX"`]',
  SEARCH_ICON: '~search icn',
  HELP_ICON: '~help icn',
  SEARCH_FIELD: '~Search All Mail'
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

  get searchField() {
    return $(SELECTORS.SEARCH_FIELD);
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
    await expect(await this.helpIcon).toBeDisplayed();
    const selector = `~${subject}`;
    if (await (await $(selector)).isDisplayed() !== true) {
      await TouchHelper.scrollDownToElement(await $(selector));
    }
    await ElementHelper.waitAndClick(await $(selector), 500);
  }

  clickCreateEmail = async () => {
    await browser.pause(2000); // todo: loading inbox. Fix this: wait until loader gone
    if (await (await this.createEmailButton).isDisplayed() !== true) {
      await TouchHelper.scrollDownToElement(await this.createEmailButton);
      await (await this.createEmailButton).waitForDisplayed();
    }
    await ElementHelper.waitAndClick(await this.createEmailButton, 1000); // delay needed on M1
  }

  clickOnUserEmail = async (email: string) => {
    await (await this.createEmailButton).waitForDisplayed();
    await $(`~${email}`).click();
  }

  checkInboxScreen = async () => {
    await expect(await this.inboxHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchIcon, 1000); // delay needed on M1
  }

  searchEmailBySubject = async (subject: string) => {
    await this.clickSearchButton();
    await (await this.searchField).setValue(`subject: '${subject}'`);
    const selector = `~${subject}`;
    await expect(await $(selector)).toBeDisplayed();
  }
}

export default new MailFolderScreen();
