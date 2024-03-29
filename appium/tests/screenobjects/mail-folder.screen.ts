import BaseScreen from './base.screen';
import TouchHelper from '../helpers/TouchHelper';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  TRASH_HEADER: '~aid-navigation-item-trash',
  AVATAR_CHECKBOX: '~aid-avatar-checkbox',
  SENT_HEADER: '~aid-navigation-item-sent',
  CREATE_EMAIL_BUTTON: '~aid-compose-message-button',
  INBOX_HEADER: '~aid-navigation-item-inbox',
  DRAFTS_HEADER: '~aid-navigation-item-drafts',
  SEARCH_BTN: '~aid-search-btn',
  HELP_BTN: '~aid-help-btn',
  SEARCH_FIELD: '~aid-search-all-emails',
  EMPTY_FOLDER_BTN: '~aid-empty-folder-button',
  // TODO: Couldn't use accessibility identifier because $$ selector returns only visible cells
  INBOX_ITEM: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeTable[2]/XCUIElementTypeCell',
  IDLE_NODE: '~aid-inbox-idle-node',
  EMPTY_CELL_NODE: '~aid-empty-cell-node',
  MOVE_TO_INBOX_BUTTON: '~aid-move-to-inbox-button',
  ARCHIVE_BUTTON: '~aid-archive-button',
  DELETE_BUTTON: '~aid-delete-button',
  INBOX_UNREAD_ITEM: `~aid-inbox-unread-item`,
  READ_BUTTON: '~aid-read-button',
  UNREAD_BUTTON: '~aid-unread-button',
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
    return $(SELECTORS.TRASH_HEADER);
  }

  get sentHeader() {
    return $(SELECTORS.SENT_HEADER);
  }

  get inboxHeader() {
    return $(SELECTORS.INBOX_HEADER);
  }

  get draftsHeader() {
    return $(SELECTORS.DRAFTS_HEADER);
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

  get avatarCheckBoxes() {
    return $$(SELECTORS.AVATAR_CHECKBOX);
  }

  get moveToInboxButton() {
    return $(SELECTORS.MOVE_TO_INBOX_BUTTON);
  }

  get archiveButton() {
    return $(SELECTORS.ARCHIVE_BUTTON);
  }

  get deleteButton() {
    return $(SELECTORS.DELETE_BUTTON);
  }

  get unreadInboxItems() {
    return $$(SELECTORS.INBOX_UNREAD_ITEM);
  }

  get readButton() {
    return $(SELECTORS.READ_BUTTON);
  }

  get unreadButton() {
    return $(SELECTORS.UNREAD_BUTTON);
  }

  get emptyFolderBtn() {
    return $(SELECTORS.EMPTY_FOLDER_BTN);
  }

  get idleNode() {
    return $(SELECTORS.IDLE_NODE);
  }

  get emptyCellNode() {
    return $(SELECTORS.EMPTY_CELL_NODE);
  }

  checkTrashScreen = async () => {
    await ElementHelper.waitElementVisible(await this.trashHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  };

  checkEmailIsDisplayed = async (subject: string) => {
    await this.checkEmailIsNotDisplayed(subject, false);
  };

  checkEmailIsNotDisplayed = async (subject: string, reverse = true) => {
    await (await $(`~${subject}`)).waitForDisplayed({ reverse });
  };

  checkSentScreen = async () => {
    await ElementHelper.waitElementVisible(await this.sentHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  };

  refreshMailList = async () => {
    await TouchHelper.pullToRefresh();
  };

  clickOnEmailBySubject = async (subject: string) => {
    await ElementHelper.waitElementInvisible(await this.idleNode);
    await browser.pause(100);
    const subjectEl = await $(`~${subject}`);
    if (!(await subjectEl.isDisplayed())) {
      await TouchHelper.scrollDownToElement(subjectEl);
    }
    await ElementHelper.waitAndClick(subjectEl, 500);
  };

  clickCreateEmail = async () => {
    await browser.pause(500);
    const elem = await this.createEmailButton;
    if (!(await elem.isDisplayed())) {
      await TouchHelper.scrollDownToElement(elem);
      await elem.waitForDisplayed();
    }
    await ElementHelper.waitAndClick(elem);
  };

  clickOnUserEmail = async (email: string) => {
    await (await this.createEmailButton).waitForDisplayed();
    await $(`~${email}`).click();
  };

  scrollDownToEmail = async (subject: string) => {
    const elem = $(`~${subject}`);
    await TouchHelper.scrollDownToElement(await elem);
  };

  tapSwipeAction = async (subject: string, side: 'leading' | 'trailing') => {
    const el = await $(`~${subject}`);
    await ElementHelper.waitElementVisible(el);
    await TouchHelper.swipeElement(el, side);
    await TouchHelper.tapSwipeAction(el, side);
  };

  checkEmailCount = async (expectedCount: number) => {
    expect(await this.getEmailCount()).toEqual(expectedCount);
  };

  getEmailCount = async () => {
    await ElementHelper.waitElementInvisible(await this.idleNode);
    await browser.pause(1000);
    return await this.inboxList.length;
  };

  scrollUpToFirstEmail = async () => {
    const elem = await this.inboxList[0];
    if (elem) {
      await TouchHelper.scrollUpToElement(elem as WebdriverIO.Element);
    }
  };

  checkInboxScreen = async () => {
    await ElementHelper.waitElementVisible(await this.inboxHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  };

  selectThread = async (index: number) => {
    const avatarCheckBoxes = await this.avatarCheckBoxes;
    await ElementHelper.waitAndClick(avatarCheckBoxes[index]);
  };

  clickOnDeleteButton = async () => {
    await ElementHelper.waitAndClick(await this.deleteButton);
  };

  clickOnArchiveButton = async () => {
    await ElementHelper.waitAndClick(await this.deleteButton);
  };

  clickOnMoveToInboxButton = async () => {
    await ElementHelper.waitAndClick(await this.moveToInboxButton);
  };

  checkUnreadEmailSubject = async (count: number, subject: string) => {
    const unreadEmailList = await this.unreadInboxItems;
    const subjectEl = await unreadEmailList[count].$(`~${subject}`);
    await ElementHelper.waitElementVisible(subjectEl);
  };

  checkUnreadEmailCount = async (count: number) => {
    const unreadEmailList = await this.unreadInboxItems;
    expect(unreadEmailList.length).toEqual(count);
  };

  clickOnReadButton = async () => {
    await ElementHelper.waitAndClick(await this.readButton);
  };

  clickOnUnreadButton = async () => {
    await ElementHelper.waitAndClick(await this.unreadButton);
  };

  checkDraftsScreen = async () => {
    await ElementHelper.waitElementVisible(await this.draftsHeader);
    await ElementHelper.waitElementVisible(await this.searchBtn);
    await ElementHelper.waitElementVisible(await this.helpBtn);
  };

  checkIfFolderIsEmpty = async () => {
    await ElementHelper.waitElementVisible(await this.emptyCellNode);
  };

  emptyFolder = async () => {
    await ElementHelper.waitAndClick(await this.emptyFolderBtn);
    await BaseScreen.clickConfirmButton();
    // Give some time to delete messages
    await browser.pause(500);
  };

  clickSearchButton = async () => {
    await ElementHelper.waitAndClick(await this.searchBtn, 1000); // delay needed on M1
  };
}

export default new MailFolderScreen();
