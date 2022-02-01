import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  CONTACTS_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Contacts"`]',
  BACK_BUTTON: '~aid-back-button',
  EMPTY_CONTACTS_LIST: '~Empty list',
  NO_PUBLIC_KEY_LABEL: '~(No public keys)'
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

  get noPublicKeyLabel() {
    return $(SELECTORS.NO_PUBLIC_KEY_LABEL);
  }

  contactName = async (name: string) => {
    return await $(`~${name}`)
  }

  checkContactScreen = async () => {
    await (await this.contactsHeader).waitForDisplayed();
  }

  checkEmptyList = async () => {
    await (await this.emptyContactsList).waitForDisplayed();
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton, 1000);
  }

  checkContact = async (name: string) => {
    const element = await this.contactName(name);
    await element.waitForDisplayed();
  }

  checkContactWithoutPubKey = async (name: string) => {
    await this.checkContact(name);
    await (await this.noPublicKeyLabel).waitForDisplayed();
  }

  clickOnContact = async (name: string) => {
    await ElementHelper.waitAndClick(await this.contactName(name));
  }
}

export default new ContactsScreen();
