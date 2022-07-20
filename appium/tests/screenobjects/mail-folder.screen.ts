import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  TRASH_HEADER: '~aid-navigation-item-trash',
  SENT_HEADER: '~aid-navigation-item-sent',
  CREATE_EMAIL_BUTTON: '~aid-compose-message-button',
  INBOX_HEADER: '~aid-navigation-item-inbox',
  SEARCH_BTN: '~aid-search-btn',
  HELP_BTN: '~aid-help-btn',
  SEARCH_FIELD: '~aid-search-all-emails',
  // INBOX_ITEM: '~aid-inbox-item',
  // TODO: Couldn't use accessibility identifier because $$ selector returns only visible cells
  INBOX_ITEM: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeTable[2]/XCUIElementTypeCell',
  IDLE_NODE: '~aid-inbox-idle-node'
};

class MailFolderScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SEARCH_BTN);
  }

  get searchBtn() {
    return $(SELECTORS.SEARCH_BTN);
  }

  get helpBtn() {
    return $(SELECTORS.HELP_BTN);
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
    return $$(SELECTORS.INBOX_ITEM);
  }

  get idleNode() {
    return $(SELECTORS.IDLE_NODE);
  }

  checkTrashScreen = async () => {
    await ElementHelper.waitElementVisible(await this.trashHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  }

  checkEmailIsNotDisplayed = async (subject: string) => {
    await (await $(`~${subject}`)).waitForDisplayed({ reverse: true });
  }

  checkSentScreen = async () => {
    await ElementHelper.waitElementVisible(await this.sentHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  }

  refreshMailList = async () => {
    await TouchHelper.pullToRefresh();
  }

  clickOnEmailBySubject = async (subject: string) => {
    await ElementHelper.waitElementInvisible(await this.idleNode);
    await browser.pause(100);
    const subjectEl = await $(`~${subject}`);
    if (!await subjectEl.isDisplayed()) {
      await TouchHelper.scrollDownToElement(subjectEl);
    }
    await ElementHelper.waitAndClick(subjectEl, 500);
  }

  clickCreateEmail = async () => {
    await browser.pause(500);
    const elem = await this.createEmailButton;
    if (!await elem.isDisplayed()) {
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
    await ElementHelper.waitElementInvisible(await this.idleNode);
    await browser.pause(1000);
    return await this.inboxList.length;
  };

  scrollUpToFirstEmail = async () => {
    const elem = await this.inboxList[0];
    if (elem) {
      await TouchHelper.scrollUpToElement(elem);
    }
  }

  checkInboxScreen = async () => {
    await ElementHelper.waitElementVisible(await this.inboxHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  }

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchBtn, 1000); // delay needed on M1
  }
}

export default new MailFolderScreen();
