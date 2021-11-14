import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  CONTACTS_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Contacts"`]',
  BACK_BUTTON: '~arrow left c',
  EMPTY_CONTACTS_LIST: '~Empty list',
};

class ContactsScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.CONTACTS_HEADER);
  }

  get contactsHeader() {
    return $(SELECTORS.CONTACTS_HEADER);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON);
  }

  get emptyContactsList() {
    return $(SELECTORS.EMPTY_CONTACTS_LIST);
  }

  contactName = async (name: string) => {
    return await $(`~${name}`)
  }

  checkContactScreen = async () => {
    await this.contactsHeader.waitForDisplayed();
    await this.backButton.waitForDisplayed();
  }

  checkEmptyList = async () => {
    await this.emptyContactsList.waitForDisplayed();
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  checkContact = async (name: string) => {
    const element = await this.contactName(name);
    await element.waitForDisplayed();
  }

  clickOnContact = async (name: string) => {
    await ElementHelper.waitAndClick(await this.contactName(name));
  }
}

export default new ContactsScreen();
