import BaseScreen from './base.screen';
import { CommonData } from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  MENU_ICON: '~menu icn',
  LOGOUT_BTN: '~Log out',
  SETTINGS_BTN: '~Settings',
  INBOX_BTN: '~INBOX',
  SENT_BTN: '~SENT'
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

  clickMenuIcon = async () => {
    await ElementHelper.waitAndClick(await this.menuIcon, 1000);
  }

  checkUserEmail = async (email: string = CommonData.account.email) => {
    const el = await $(`~${email}`);
    await el.waitForDisplayed();
  }

  checkMenuBar = async () => {
    await ElementHelper.waitElementVisible(await this.logoutButton);
    await ElementHelper.waitElementVisible(await this.settingsButton);
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
}

export default new MenuBarScreen();
