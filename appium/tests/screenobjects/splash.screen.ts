import BaseScreen from './base.screen';
import { CommonData } from '../data';
import ElementHelper from '../helpers/ElementHelper';
import { EmailProviderScreen } from '../screenobjects/all-screens';

const SELECTORS = {
  PRIVACY_TAB: '~aid-privacy-btn',
  TERMS_TAB: '~aid-terms-btn',
  SECURITY_TAB: '~aid-security-btn',
  CONTINUE_WITH_GOOGLE_BTN: '~aid-sign-in-gmail-btn',
  CONTINUE_WITH_OUTLOOK_BTN: '~aid-sign-in-outlook-btn',
  OTHER_EMAIL_PROVIDER_BTN: '~aid-sign-in-other-btn',
  // We can't use aid identifier for below fields because belows fields are from google oauth popup
  CONTINUE_BTN: '~Continue',
  CANCEL_BTN: '~Cancel',
  LOGIN_FIELD: '~Email or phone',
  NEXT_BTN: '-ios class chain:**/XCUIElementTypeButton[`label == "Next"`][1]',
  PASSWORD_FIELD: '~Enter your password',
  DONE_BTN: '~Done',
  LANGUAGE_DROPDOWN:
    '-ios class chain:**/XCUIElementTypeOther[`label == "content information"`]/XCUIElementTypeOther[1]',
  SIGN_IN_WITH_GMAIL: '-ios class chain:**/XCUIElementTypeOther[`label == "Sign in - Google Accounts"`]',
  USE_ANOTHER_ACCOUNT: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Use another account"`]',
};

class SplashScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.PRIVACY_TAB);
  }

  get privacyTab() {
    return $(SELECTORS.PRIVACY_TAB);
  }

  get termsTab() {
    return $(SELECTORS.TERMS_TAB);
  }

  get securityTab() {
    return $(SELECTORS.SECURITY_TAB);
  }

  get continueWithGmailBtn() {
    return $(SELECTORS.CONTINUE_WITH_GOOGLE_BTN);
  }

  get continueWithOutlookBtn() {
    return $(SELECTORS.CONTINUE_WITH_OUTLOOK_BTN);
  }

  get otherEmailProviderButton() {
    return $(SELECTORS.OTHER_EMAIL_PROVIDER_BTN);
  }

  get continueButton() {
    return $(SELECTORS.CONTINUE_BTN);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BTN);
  }

  get loginField() {
    return $(SELECTORS.LOGIN_FIELD);
  }

  get passwordField() {
    return $(SELECTORS.PASSWORD_FIELD);
  }

  get nextButton() {
    return $(SELECTORS.NEXT_BTN);
  }

  get doneButton() {
    return $(SELECTORS.DONE_BTN);
  }

  get languageDropdown() {
    return $(SELECTORS.LANGUAGE_DROPDOWN);
  }

  get signInAsGoogleAccounLabel() {
    return $(SELECTORS.SIGN_IN_WITH_GMAIL);
  }

  get useAnotherAccount() {
    return $(SELECTORS.USE_ANOTHER_ACCOUNT);
  }

  checkLoginPage = async () => {
    await ElementHelper.waitElementVisible(await this.privacyTab);
    await ElementHelper.waitElementVisible(await this.termsTab);
    await ElementHelper.waitElementVisible(await this.securityTab);
    await ElementHelper.waitElementVisible(await this.continueWithGmailBtn);
    // these login methods currently disabled on ios
    // await ElementHelper.waitElementVisible(await this.continueWithOutlookBtn);
    // await ElementHelper.waitElementVisible(await this.otherEmailProviderButton);
  };

  clickContinueWithGmail = async () => {
    await ElementHelper.waitAndClick(await this.continueWithGmailBtn);
  };

  clickOtherEmailProvider = async () => {
    await ElementHelper.waitAndClick(await this.otherEmailProviderButton);
  };

  clickContinueBtn = async () => {
    // expect(await this.continueButton).toBeDisplayed();
    // expect(await this.cancelButton).toBeDisplayed();
    await ElementHelper.waitAndClick(await this.continueButton);
  };

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  };

  changeLanguage = async (language = '‪English (United States)‬') => {
    await ElementHelper.waitAndClick(await this.languageDropdown, 500);
    const selector = `~${language}`;
    const langEl = await $(selector);
    await langEl.waitForDisplayed({ timeout: 15000 });
    if (await langEl.isDisplayed()) {
      await ElementHelper.waitAndClick(langEl);
    } else {
      // eslint-disable-next-line no-irregular-whitespace
      const newLangEl = await $(`"​ ‪English (United States)‬`);
      await ElementHelper.waitAndClick(newLangEl);
    }
  };

  fillEmail = async (email: string) => {
    await ElementHelper.waitClickAndType(await this.loginField, email);
    await this.clickDoneBtn();
    await browser.pause(500); // stability sleep
  };

  fillPassword = async (password: string) => {
    await ElementHelper.waitClickAndType(await this.passwordField, password);
    await this.clickDoneBtn();
    await browser.pause(500); // stability sleep
  };

  clickNextBtn = async () => {
    await ElementHelper.waitAndClick(await this.nextButton);
  };

  clickDoneBtn = async () => {
    await ElementHelper.waitAndClick(await this.doneButton);
  };

  gmailLogin = async (email: string, password: string) => {
    const emailSelector = `-ios class chain:**/XCUIElementTypeLink/XCUIElementTypeStaticText[\`label == "${email}"\`]`;
    await (await this.signInAsGoogleAccounLabel).waitForDisplayed();
    await browser.pause(1000); // stability sleep for language change
    if (await (await $(emailSelector)).isDisplayed()) {
      await ElementHelper.waitAndClick(await $(emailSelector));
      await (await this.useAnotherAccount).waitForDisplayed({ timeout: 5000, reverse: true });
      if (await (await this.passwordField).isDisplayed()) {
        await this.fillPassword(password);
        await this.clickNextBtn();
      }
    } else {
      await this.fillEmail(email);
      await this.clickNextBtn();
      await this.fillPassword(password);
      await this.clickNextBtn();
    }
  };

  login = async (
    email: string = CommonData.account.email,
    password: string = CommonData.account.password!,
    isMock = false,
  ) => {
    await this.clickContinueWithGmail();
    await this.clickContinueBtn();

    if (!isMock) {
      await this.changeLanguage();
      await this.gmailLogin(email, password);
    }

    await ElementHelper.waitElementInvisible(await this.signInAsGoogleAccounLabel);
  };

  loginToOtherEmailProvider = async (
    email: string = CommonData.outlookAccount.email,
    password: string = CommonData.outlookAccount.password!,
  ) => {
    await this.clickOtherEmailProvider();
    await EmailProviderScreen.checkEmailProviderScreen();
    await EmailProviderScreen.fillEmail(email);
    await EmailProviderScreen.fillPassword(password);
    await EmailProviderScreen.clickConnectBtn();
  };

  mockLogin = async () => {
    await this.login('', '', true);
  };
}

export default new SplashScreen();
