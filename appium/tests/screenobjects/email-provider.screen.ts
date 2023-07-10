import BaseScreen from './base.screen';
import ElementHelper from '../helpers/ElementHelper';
import TouchHelper from '../helpers/TouchHelper';

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  EMAIL_PROVIDER_HEADER: '~aid-navigation-item-email-provider',
  CONNECT_BUTTON: '~aid-connect-button',
  EMAIL_FIELD: '~aid-email-textfield',
  PASSWORD_FIELD: '~aid-password-textfield',
  RETURN_BUTTON: '~Return',
};

class EmailProviderScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN);
  }

  get emailProviderHeader() {
    return $(SELECTORS.EMAIL_PROVIDER_HEADER);
  }

  get connectButton() {
    return $(SELECTORS.CONNECT_BUTTON);
  }

  get emailField() {
    return $(SELECTORS.EMAIL_FIELD);
  }

  get passwordField() {
    return $(SELECTORS.PASSWORD_FIELD);
  }

  get returnButton() {
    return $(SELECTORS.RETURN_BUTTON);
  }

  checkEmailProviderScreen = async () => {
    await expect(this.backButton).toBeDisplayed();
    await expect(this.emailProviderHeader).toBeDisplayed();
    await expect(this.connectButton).toBeDisplayed();
  };

  fillEmail = async (email: string) => {
    await ElementHelper.waitClickAndType(await this.emailField, email);
    await browser.pause(500);
  };

  fillPassword = async (password: string) => {
    await ElementHelper.waitClickAndType(await this.passwordField, password);
    await browser.pause(500); // stability sleep
  };

  clickConnectBtn = async () => {
    await TouchHelper.scrollUp();
    await ElementHelper.waitAndClick(await this.connectButton);
  };

  clickReturnBtn = async () => {
    await ElementHelper.waitAndClick(await this.returnButton);
  };
}

export default new EmailProviderScreen();
