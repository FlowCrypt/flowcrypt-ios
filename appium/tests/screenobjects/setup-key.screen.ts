import BaseScreen from './base.screen';
import { CommonData } from '../data';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  SET_PASS_PHRASE_BUTTON: '~aid-set-pass-phrase-btn',
  ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
  OK_BUTTON: '~Ok',
  CONFIRM_PASS_PHRASE_FIELD: '~textField',
  LOAD_ACCOUNT_BUTTON: '~aid-load-account-btn',
  CREATE_NEW_KEY_BUTTON: '~aid-create-new-key-button',
  IMPORT_MY_KEY_BUTTON: '~aid-import-my-key-button'
};

class SetupKeyScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SET_PASS_PHRASE_BUTTON);
  }

  get setPassPhraseButton() {
    return $(SELECTORS.SET_PASS_PHRASE_BUTTON);
  }

  get loadAccountButton() {
    return $(SELECTORS.LOAD_ACCOUNT_BUTTON)
  }

  get enterPassPhraseField() {
    return $(SELECTORS.ENTER_YOUR_PASS_PHRASE_FIELD);
  }

  get okButton() {
    return $(SELECTORS.OK_BUTTON)
  }

  get confirmPassPhraseField() {
    return $(SELECTORS.CONFIRM_PASS_PHRASE_FIELD)
  }

  get createNewKeyButton() {
    return $(SELECTORS.CREATE_NEW_KEY_BUTTON)
  }

  get importMyKeyButton() {
    return $(SELECTORS.IMPORT_MY_KEY_BUTTON)
  }

  setPassPhrase = async (withManualSubmit = true, text: string = CommonData.account.passPhrase) => {
    // retrying several times because following login, we switch
    //   from webview to our own view and then to another one several
    //   times, which was causing flaky tests. Originally we did a 10s
    //   delay but now instead we're retrying once per second until
    //   we see what we expect.
    let count = 0;
    do {
      await browser.pause(1000);
      count++;
    } while (await (await this.enterPassPhraseField).isDisplayed() !== true && count <= 15);

    if (withManualSubmit) {
      await this.fillPassPhraseManually(text);
      await this.clickSetPassPhraseBtn();
      await this.confirmPassPhraseManually(text);
    } else {
      await this.fillPassPhrase(text);
      await this.confirmPassPhrase(text);
    }
  }

  setPassPhraseForOtherProviderEmail = async (text: string = CommonData.outlookAccount.passPhrase) => {

    // retrying several times because following login, we switch
    //   from webview to our own view and then to another one several
    //   times, which was causing flaky tests. Originally we did a 10s
    //   delay but now instead we're retrying once per second until
    //   we see what we expect.

    let count = 0;
    do {
      await browser.pause(1000);
      count++;
    } while ((await (await this.loadAccountButton).isDisplayed() !== true && await (await this.createNewKeyButton).isDisplayed() !== true) && count <= 15);

    if (await (await this.enterPassPhraseField).isDisplayed() !== true) {
      await this.clickCreateNewKeyButton();
      await this.fillPassPhrase(text);
      await this.confirmPassPhrase(text);
    } else {
      await this.fillPassPhrase(text);
      await this.clickLoadAccountButton();
    }
  }

  fillPassPhrase = async (passPhrase: string) => {
    await ElementHelper.waitAndPasteString(await this.enterPassPhraseField, passPhrase);
  }

  fillPassPhraseManually = async (passPhrase: string) => {
    await ElementHelper.waitClickAndType(await this.enterPassPhraseField, passPhrase);
  }

  clickSetPassPhraseBtn = async () => {
    await ElementHelper.waitAndClick(await this.setPassPhraseButton);
  }

  clickLoadAccountButton = async () => {
    await ElementHelper.waitAndClick(await this.loadAccountButton);
  }

  confirmPassPhrase = async (passPhrase: string) => {
    await ElementHelper.waitAndPasteString(await this.confirmPassPhraseField, passPhrase);
  }

  confirmPassPhraseManually = async (passPhrase: string) => {
    await ElementHelper.waitClickAndType(await this.confirmPassPhraseField, passPhrase);
    await ElementHelper.waitAndClick(await this.okButton);
  }

  clickCreateNewKeyButton = async () => {
    await ElementHelper.waitAndClick(await this.createNewKeyButton);
  }

  checkNoBackupsFoundScreen = async () => {
    await ElementHelper.waitElementVisible(await this.createNewKeyButton);
    await ElementHelper.waitElementVisible(await this.importMyKeyButton);
  }
}

export default new SetupKeyScreen();
