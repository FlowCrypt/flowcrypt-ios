import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  CONTACTS_HEADER: '~aid-navigation-item-contacts',
  BACK_BUTTON: '~aid-back-button',
  EMPTY_CONTACTS_LIST: '~Empty list',
  NO_PUBLIC_KEY_LABEL: '~(No public keys)', // Can't use `aid` identifier because string is generated dynamically depends on public key count
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
    return await $(`~${name}`);
  };

  checkContactScreen = async () => {
    await (await this.contactsHeader).waitForDisplayed();
  };

  checkEmptyList = async () => {
    await (await this.emptyContactsList).waitForDisplayed();
  };

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton, 1000);
  };

  checkContact = async (name: string) => {
    const element = await this.contactName(name);
    await element.waitForDisplayed();
  };

  checkContactWithoutPubKey = async (name: string) => {
    await this.checkContact(name);
    await (await this.noPublicKeyLabel).waitForDisplayed();
  };

  clickOnContact = async (name: string) => {
    await ElementHelper.waitAndClick(await this.contactName(name));
  };

  checkContactOrder = async (email: string, order: number) => {
    const user = `-ios class chain:**/XCUIElementTypeOther[\`label == "${order}"\`]/XCUIElementTypeStaticText[\`label == "${email}"\`]`;
    await ElementHelper.waitElementVisible(await $(user));
  };

  checkContactIsNotDisplayed = async (email: string, order: number) => {
    const user = `-ios class chain:**/XCUIElementTypeOther[\`label == "${order}"\`]/XCUIElementTypeStaticText[\`label == "${email}"\`]`;
    await ElementHelper.waitElementInvisible(await $(user));
  };

  clickRemoveButton = async (order: number) => {
    const removeButton = `-ios class chain:**/XCUIElementTypeOther[\`label == "${order}"\`]/XCUIElementTypeButton`;
    await ElementHelper.waitAndClick(await $(removeButton));
  };
}

export default new ContactsScreen();
