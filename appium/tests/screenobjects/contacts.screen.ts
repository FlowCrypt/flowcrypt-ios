import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';

const SELECTORS = {
  CONTACTS_HEADER: '~aid-navigation-item-contacts',
  BACK_BUTTON: '~aid-back-button',
  ADD_CONTACT_BUTTON: '~aid-add-contact-button',
  CONTACT_ITEM: '~aid-contact-item',
  NO_PUBLIC_KEY_LABEL: '~(No public keys)', // Can't use `aid` identifier because string is generated dynamically depends on public key count
};

class ContactsScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.CONTACTS_HEADER);
  }

  get contactsHeader() {
    return $(SELECTORS.CONTACTS_HEADER);
  }

  get contactItems() {
    return $$(SELECTORS.CONTACT_ITEM);
  }

  get addContactButton() {
    return $(SELECTORS.ADD_CONTACT_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON);
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
    expect((await this.contactItems).length).toBe(0);
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

  clickOnAddContactButton = async () => {
    await ElementHelper.waitAndClick(await this.addContactButton);
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
