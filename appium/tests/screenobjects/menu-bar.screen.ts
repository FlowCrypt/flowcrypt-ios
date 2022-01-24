import BaseScreen from './base.screen';
import { CommonData } from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  MENU_ICON: '~menu icn',
  LOGOUT_BTN: '~menuBarItemLog out',
  SETTINGS_BTN: '~menuBarItemSettings',
  INBOX_BTN: '~menuBarItemInbox',
  SENT_BTN: '~menuBarItemSent',
  TRASH_BTN: '~menuBarItemTrash',
  ADD_ACCOUNT_BUTTON: '~Add account'
};

class MenuBarScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.MENU_ICON);
  }

  get menuIcon() {
    return $(SELECTORS.MENU_ICON);
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
    return $(SELECTORS.TRASH_BTN)
  }

  get addAccountButton() {
    return $(SELECTORS.ADD_ACCOUNT_BUTTON);
  }

  clickMenuIcon = async () => {
    await ElementHelper.waitAndClick(await this.menuIcon, 1000);
    await this.checkMenuBar();
  }

  checkUserEmail = async (email: string = CommonData.account.email) => {
    const el = await $(`~${email}`);
    await el.waitForDisplayed();
  }

  clickOnUserEmail = async (email: string = CommonData.account.email) => {
    const el = await $(`~${email}`);
    await ElementHelper.waitAndClick(await el);
  }

  clickAddAccountButton = async() => {
    await ElementHelper.waitAndClick(await this.addAccountButton);
  }

  checkMenuBar = async () => {
    await ElementHelper.waitElementVisible(await this.logoutButton);
    await ElementHelper.waitElementVisible(await this.settingsButton);
    await ElementHelper.waitElementVisible(await this.inboxButton);
    await ElementHelper.waitElementVisible(await this.sentButton);
    await ElementHelper.waitElementVisible(await this.trashButton);
  }

  clickLogout = async () => {
    await ElementHelper.waitAndClick(await this.logoutButton);
  }

  clickSettingsButton = async () => {
    await ElementHelper.waitAndClick(await this.settingsButton);
  }

  clickInboxButton = async () => {
    await ElementHelper.waitAndClick(await this.inboxButton);
  }

  clickSentButton = async () => {
    await ElementHelper.waitAndClick(await this.sentButton);
  }

  clickTrashButton = async () => {
    await ElementHelper.waitAndClick(await this.trashButton);
  }

  checkMenuBarItem = async (menuItem: string) => {
    const menuBarItem = await $(`~menuBarItem${menuItem}`);
    await menuBarItem.waitForDisplayed();
  }

  selectAccount = async (order: number) => {
    const ele = await $(`~aid-account-email-${order-1}`);
    await ElementHelper.waitAndClick(await ele);
  }
}

export default new MenuBarScreen();
