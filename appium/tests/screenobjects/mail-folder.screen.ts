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
  IDLE_NODE: '~aid-inbox-idle-node'
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

  get idleNode() {
    return $(SELECTORS.IDLE_NODE);
  }

  checkTrashScreen = async () => {
    await ElementHelper.waitElementVisible(await this.trashHeader);
    await ElementHelper.waitElementVisible(await this.searchIcon);
    await ElementHelper.waitElementVisible(await this.helpIcon);
  }

  checkEmailIsNotDisplayed = async (subject: string) => {
    await (await $(`~${subject}`)).waitForDisplayed({ reverse: true });
  }

  checkSentScreen = async () => {
    await ElementHelper.waitElementVisible(await this.sentHeader);
    await ElementHelper.waitElementVisible(await this.searchIcon);
    await ElementHelper.waitElementVisible(await this.helpIcon);
  }

  refreshMailList = async () => {
    await TouchHelper.pullToRefresh();
  }

  clickOnEmailBySubject = async (subject: string) => {
    const selector = `~${subject}`;
    if (!await (await $(selector)).isDisplayed()) {
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
    await ElementHelper.waitElementInvisible(await this.idleNode);
    await browser.pause(1000);
    return await this.inboxList.length;
  };

  scrollUpToFirstEmail = async () => {
    const elem = this.inboxList[0];
    if (elem) {
      await TouchHelper.scrollUpToElement(elem);
    }
  }

  checkInboxScreen = async () => {
    await ElementHelper.waitElementVisible(await this.inboxHeader);
    await ElementHelper.waitElementVisible(await this.searchIcon);
    await ElementHelper.waitElementVisible(await this.helpIcon);
  }

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchIcon, 1000); // delay needed on M1
  }
}

export default new MailFolderScreen();
