import BaseScreen from './base.screen';
import { CommonData } from '../data';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  MENU_BTN: '~aid-menu-btn',
  LOGOUT_BTN: '~aid-menu-bar-item-log-out',
  SETTINGS_BTN: '~aid-menu-bar-item-settings',
  INBOX_BTN: '~aid-menu-bar-item-inbox',
  SENT_BTN: '~aid-menu-bar-item-sent',
  TRASH_BTN: '~aid-menu-bar-item-trash',
  DRAFTS_BTN: '~aid-menu-bar-item-drafts',
  ALL_MAIL_BTN: '~aid-menu-bar-item-all-mail',
  ADD_ACCOUNT_BUTTON: '~aid-add-account-btn',
};

class MenuBarScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.MENU_BTN);
  }

  get menuBtn() {
    return $(SELECTORS.MENU_BTN);
  }

  get logoutButton() {
    return $(SELECTORS.LOGOUT_BTN);
  }

  get settingsButton() {
    return $(SELECTORS.SETTINGS_BTN);
  }

  get inboxButton() {
    return $(SELECTORS.INBOX_BTN);
  }

  get sentButton() {
    return $(SELECTORS.SENT_BTN);
  }

  get trashButton() {
    return $(SELECTORS.TRASH_BTN);
  }

  get draftsButton() {
    return $(SELECTORS.DRAFTS_BTN);
  }

  get allMailButton() {
    return $(SELECTORS.ALL_MAIL_BTN);
  }

  get addAccountButton() {
    return $(SELECTORS.ADD_ACCOUNT_BUTTON);
  }

  clickMenuBtn = async () => {
    await ElementHelper.waitAndClick(await this.menuBtn, 1000);
    await this.checkMenuBar();
  };

  checkUserEmail = async (email: string = CommonData.account.email) => {
    const el = await $(`~${email}`);
    await el.waitForDisplayed();
  };

  clickOnUserEmail = async (email: string = CommonData.account.email) => {
    const el = await $(`~${email}`);
    await ElementHelper.waitAndClick(el);
  };

  clickAddAccountButton = async () => {
    await ElementHelper.waitAndClick(await this.addAccountButton);
  };

  checkMenuBar = async () => {
    await ElementHelper.waitElementVisible(await this.logoutButton);
    await ElementHelper.waitElementVisible(await this.settingsButton);
    await ElementHelper.waitElementVisible(await this.inboxButton);
    await ElementHelper.waitElementVisible(await this.sentButton);
    await ElementHelper.waitElementVisible(await this.trashButton);
  };

  clickLogout = async () => {
    await ElementHelper.waitAndClick(await this.logoutButton);
  };

  clickSettingsButton = async () => {
    await ElementHelper.waitAndClick(await this.settingsButton);
  };

  clickInboxButton = async () => {
    await ElementHelper.waitAndClick(await this.inboxButton);
  };

  clickSentButton = async () => {
    await ElementHelper.waitAndClick(await this.sentButton);
  };

  clickTrashButton = async () => {
    await ElementHelper.waitAndClick(await this.trashButton);
  };

  clickDraftsButton = async () => {
    await ElementHelper.waitAndClick(await this.draftsButton);
  };

  clickAllMailButton = async () => {
    await ElementHelper.waitAndClick(await this.allMailButton);
  };

  checkMenuBarItem = async (menuItem: string) => {
    const menuBarItem = await $(`~aid-menu-item-${menuItem}`);
    await menuBarItem.waitForDisplayed();
  };

  selectAccount = async (order: number) => {
    const ele = await $(`~aid-account-email-${order - 1}`);
    await ElementHelper.waitAndClick(ele);
  };
}

export default new MenuBarScreen();
