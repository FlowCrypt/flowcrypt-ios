import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import { KeyDetailInfo } from "../../api-mocks/apis/ekm/ekm-endpoints";
import {
  MenuBarScreen,
  SettingsScreen
} from '../screenobjects/all-screens';

const SELECTORS = {
  KEYS_HEADER: '~aid-navigation-item-keys',
  ADD_BUTTON: '~aid-add-button',
  NAME_AND_EMAIL: '~aid-key-title',
  DATE_CREATED: '~aid-key-date-created',
  FINGERPRINT: '~aid-key-subtitle',
  SHOW_PUBLIC_KEY_BUTTON: '~aid-key-public-info',
  SHOW_KEY_DETAILS_BUTTON: '~aid-key-details',
  COPY_TO_CLIPBOARD_BUTTON: '~aid-key-copy',
  SHARE_BUTTON: '~aid-key-share',
  SHOW_PRIVATE_KEY_BUTTON: '~aid-key-private-info',
  BACK_BUTTON: '~aid-back-button',
  EMPTY_VIEW: '~aid-key-empty-view'
};

class KeysScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.KEYS_HEADER);
  }

  get keysHeader() {
    return $(SELECTORS.KEYS_HEADER);
  }

  get addButton() {
    return $(SELECTORS.ADD_BUTTON);
  }

  get nameAndEmail() {
    return $$(SELECTORS.NAME_AND_EMAIL);
  }

  get dateCreated() {
    return $$(SELECTORS.DATE_CREATED);
  }

  get fingerPrint() {
    return $$(SELECTORS.FINGERPRINT);
  }

  get showPublicKeyButton() {
    return $(SELECTORS.SHOW_PUBLIC_KEY_BUTTON);
  }

  get showPrivateKeyButton() {
    return $(SELECTORS.SHOW_PRIVATE_KEY_BUTTON);
  }

  get showKeyDetailsButton() {
    return $(SELECTORS.SHOW_KEY_DETAILS_BUTTON);
  }

  get shareButton() {
    return $(SELECTORS.SHARE_BUTTON);
  }

  get copyToClipboardButton() {
    return $(SELECTORS.COPY_TO_CLIPBOARD_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON)
  }

  get emptyView() {
    return $(SELECTORS.EMPTY_VIEW)
  }

  checkIfKeysAreEmpty = async () => {
    await ElementHelper.waitElementVisible(await this.emptyView);
  }

  checkKeysScreen = async (keys: KeyDetailInfo[]) => {
    await (await this.keysHeader).waitForDisplayed();
    await (await this.addButton).waitForDisplayed({ reverse: true });
    await this.checkKeys(keys);
  }

  private checkKeys = async (keys: KeyDetailInfo[]) => {
    expect((await this.fingerPrint).length).toEqual(keys.length);
    for (const [index, key] of keys.entries()) {
      const fingerPrints = await (await this.fingerPrint)[index].getText();
      expect(fingerPrints).toContain(key.primaryFingerprint ?? '');
      expect(await (await this.nameAndEmail)[index].getValue()).toEqual(key.renderedPrimaryUid ?? '');
      expect(await (await this.dateCreated)[index].getValue()).toEqual(key.renderedDateCreated ?? '');
    }
  }

  clickOnKey = async (index = 0) => {
    await ElementHelper.waitAndClick((await this.nameAndEmail)[index]);
  }

  checkSelectedKeyScreen = async () => {
    await (await this.showPublicKeyButton).waitForDisplayed();
    await (await this.showPrivateKeyButton).waitForDisplayed({ reverse: true });
    await (await this.showKeyDetailsButton).waitForDisplayed();
    await (await this.shareButton).waitForDisplayed();
    await (await this.copyToClipboardButton).waitForDisplayed();
  }

  clickOnShowPublicKey = async () => {
    await ElementHelper.waitAndClick(await this.showPublicKeyButton);
  }

  clickBackButton = async () => {
    await this.backButton.click();
  }

  openScreenFromSideMenu = async () => {
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.clickOnSettingItem('Keys');
  }
}

export default new KeysScreen();
