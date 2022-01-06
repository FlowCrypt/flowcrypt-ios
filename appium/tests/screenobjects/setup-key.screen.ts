import BaseScreen from './base.screen';
import { CommonData } from '../data';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  SET_PASS_PHRASE_BUTTON: '~Set pass phrase',
  ENTER_YOUR_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
  OK_BUTTON: '~Ok',
  CONFIRM_PASS_PHRASE_FIELD: '~textField',
  LOAD_ACCOUNT_BUTTON: '~load_account',
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

  setPassPhrase = async (text: string = CommonData.account.passPhrase) => {
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
    await this.fillPassPhrase(text);
    await this.clickSetPassPhraseBtn();
    await this.confirmPassPhrase(text);
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
    } while (await (await this.enterPassPhraseField).isDisplayed() !== true && count <= 15);
    await this.fillPassPhrase(text);
    await this.clickLoadAccountButton();
  }

  fillPassPhrase = async (passPhrase: string) => {
    await ElementHelper.waitClickAndType(await this.enterPassPhraseField, passPhrase);
  }

  clickSetPassPhraseBtn = async () => {
    await ElementHelper.waitAndClick(await this.setPassPhraseButton);
  }

  clickLoadAccountButton = async () => {
    await ElementHelper.waitAndClick(await this.loadAccountButton);
  }

  confirmPassPhrase = async (passPhrase: string) => {
    await ElementHelper.waitClickAndType(await this.confirmPassPhraseField, passPhrase);
    await ElementHelper.waitAndClick(await this.okButton);
  }
}

export default new SetupKeyScreen();
