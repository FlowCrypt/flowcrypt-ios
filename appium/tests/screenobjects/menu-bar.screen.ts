import BaseScreen from './base.screen';
import { CommonData } from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  MENU_ICON: '~menu icn',
  LOGOUT_BTN: '~Log out',
  SETTINGS_BTN: '~Settings',
  INBOX_BTN: '~INBOX'
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

  clickMenuIcon = async () => {
    await ElementHelper.waitAndClick(await this.menuIcon, 200);
  }

  checkUserEmail = async (email: string = CommonData.account.email) => {
    const selector = `~${email}`;
    await $(selector).waitForDisplayed();
  }

  checkMenuBar = async () => {
    expect(await this.logoutButton).toBeDisplayed();
    expect(await this.settingsButton).toBeDisplayed();
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
}

export default new MenuBarScreen();
