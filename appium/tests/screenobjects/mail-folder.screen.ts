import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  TRASH_HEADER: '~navigationItemTrash',
  SENT_HEADER: '~navigationItemSent',
  CREATE_EMAIL_BUTTON: '~aid-compose-message-button',
  INBOX_HEADER: '~navigationItemInbox',
  SEARCH_ICON: '~search icn',
  HELP_ICON: '~help icn',
  SEARCH_FIELD: '~searchAllEmailField',
  INBOX_LIST: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeTable[2]/XCUIElementTypeCell',
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

  get inboxList() {
    return $$(SELECTORS.INBOX_LIST);
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
    await TouchHelper.pullToRefresh();
  }

  clickOnEmailBySubject = async (subject: string) => {
    const selector = `~${subject}`;
    if (await (await $(selector)).isDisplayed() !== true) {
      await TouchHelper.scrollDownToElement(await $(selector));
    }
    await ElementHelper.waitAndClick(await $(selector), 500);
  }

  clickCreateEmail = async () => {
    await browser.pause(500);
    const elem = await this.createEmailButton;
    if ((await elem.isDisplayed()) !== true) {
      await TouchHelper.scrollDownToElement(elem);
      await elem.waitForDisplayed();
    }
    await ElementHelper.waitAndClick(elem);
  }

  clickOnUserEmail = async (email: string) => {
    await (await this.createEmailButton).waitForDisplayed();
    await $(`~${email}`).click();
  }

  scrollDownToEmail = async (subject: string) => {
    const elem = $(`~${subject}`);
    await TouchHelper.scrollDownToElement(await elem);
  };

  getEmailCount = async () => {
      await browser.pause(1000);
      return await this.inboxList.length;
  };

  scrollUpToFirstEmail = async () => {
    const elem = await this.inboxList[0];
    await TouchHelper.scrollUpToElement(elem);
  }

  checkInboxScreen = async () => {
    await expect(await this.inboxHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchIcon, 1000); // delay needed on M1
  }
}

export default new MailFolderScreen();
