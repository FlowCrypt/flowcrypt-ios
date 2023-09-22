import ElementHelper from 'tests/helpers/ElementHelper';
import BaseScreen from './base.screen';

const SELECTORS = {
  BACK_BUTTON: '~aid-back-button',
  ALLOW_PASTE_BUTTON: '~Allow Paste',
  IMPORT_FROM_CLIPBOARD_BUTTON: '~aid-import-from-clipboard-button',
  IMPORT_FROM_FILE_BUTTON: '~aid-import-from-file-button',
};

class AddContactScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON);
  }

  get allowPasteButton() {
    return $(SELECTORS.ALLOW_PASTE_BUTTON);
  }

  get importFromClipboardButton() {
    return $(SELECTORS.IMPORT_FROM_CLIPBOARD_BUTTON);
  }

  get importFromFileButton() {
    return $(SELECTORS.IMPORT_FROM_CLIPBOARD_BUTTON);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  };

  checkAddContactScreen = async () => {
    await ElementHelper.waitElementVisible(await this.importFromFileButton);
    await ElementHelper.waitElementVisible(await this.importFromClipboardButton);
  };

  importPublicKey = async (publicKey: string) => {
    await ElementHelper.copyStringIntoClipboard(publicKey);
    await ElementHelper.waitAndClick(await this.importFromClipboardButton);
    await ElementHelper.waitAndClick(await this.allowPasteButton);
  };
}

export default new AddContactScreen();
