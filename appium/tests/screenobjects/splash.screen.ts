import BaseScreen from './base.screen';
import {CommonData} from "../data";

const SELECTORS = {
    PRIVACY_TAB: '~privacy',
    TERMS_TAB: '~terms',
    SECURITY_TAB: '~security',
    CONTINUE_WITH_GOOGLE_BTN: '~Continue with Gmail',
    CONTINUE_WITH_OUTLOOK_BTN: '~Continue with Outlook',
    OTHER_EMAIL_PROVIDER_BTN: '~Other email provider',
    CONTINUE_BTN: '~Continue',
    CANCEL_BTN: '~Cancel',
    LOGIN_FIELD: '~Email or phone',
    NEXT_BTN: '-ios class chain:**/XCUIElementTypeButton[`label == "Next"`][1]',
    PASSWORD_FIELD: '~Enter your password',
    DONE_BTN: '~Done',
    LANGUAGE_DROPDOWN: '-ios class chain:**/XCUIElementTypeOther[`label == "content information"`]/XCUIElementTypeOther[1]',
};

class SplashScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.PRIVACY_TAB);
    }

    get privacyTab () {
        return $(SELECTORS.PRIVACY_TAB);
    }

    get termsTab () {
        return $(SELECTORS.TERMS_TAB);
    }

    get securityTab () {
        return $(SELECTORS.SECURITY_TAB);
    }

    get continueWithGmailBtn () {
        return $(SELECTORS.CONTINUE_WITH_GOOGLE_BTN);
    }

    get continueWithOutlookBtn () {
        return $(SELECTORS.CONTINUE_WITH_OUTLOOK_BTN);
    }

    get otherEmailProviderButton () {
        return $(SELECTORS.OTHER_EMAIL_PROVIDER_BTN);
    }

    get continueButton () {
        return $(SELECTORS.CONTINUE_BTN);
    }

    get cancelButton () {
        return $(SELECTORS.CANCEL_BTN);
    }

    get loginField () {
        return $(SELECTORS.LOGIN_FIELD);
    }

    get passwordField () {
        return $(SELECTORS.PASSWORD_FIELD);
    }

    get nextButton () {
        return $(SELECTORS.NEXT_BTN);
    }

    get doneButton () {
        return $(SELECTORS.DONE_BTN)
    }

    get languageDropdown () {
        return $(SELECTORS.LANGUAGE_DROPDOWN)
    }

    checkLoginPage () {
        expect(this.privacyTab).toBeDisplayed();
        expect(this.termsTab).toBeDisplayed();
        expect(this.securityTab).toBeDisplayed();
        expect(this.continueWithGmailBtn).toBeDisplayed();
        expect(this.continueWithOutlookBtn).toBeDisplayed();
        expect(this.otherEmailProviderButton).toBeDisplayed();
    }

    clickContinueWithGmail () {
        this.continueWithGmailBtn.click();
    }

    clickContinueBtn () {
        expect(this.continueButton).toBeDisplayed();
        expect(this.cancelButton).toBeDisplayed();
        this.continueButton.click();
    }

    changeLanguage (language: string = '‪English (United States)‬') {
        this.languageDropdown.click();
        const selector = `~${language}`;
        $(selector).waitForDisplayed();
        $(selector).click();
    }

    fillEmail (email: string) {
        this.loginField.click();
        this.loginField.setValue(email);
        this.doneButton.click();
        this.nextButton.waitForDisplayed();
    }

    clickNextBtn () {
        this.nextButton.click();
    }

    fillPassword(password: string) {
        this.passwordField.click();
        this.passwordField.setValue(password);
        this.doneButton.click();
        this.nextButton.waitForDisplayed();
    }

    gmailLogin (email: string, password: string) {
        const emailSelector = `-ios class chain:**/XCUIElementTypeStaticText[\`label == "${email}"\`]`;
        if($(emailSelector).isDisplayed()) {
            $(emailSelector).click();
        } else {
            this.fillEmail(email);
            this.clickNextBtn();
            this.fillPassword(password);
            this.clickNextBtn();
        }
    }

    login(email: string = CommonData.account.email, password: string = CommonData.account.password) {
        driver.launchApp();
        this.clickContinueWithGmail();
        this.clickContinueBtn();
        this.changeLanguage();
        this.gmailLogin(email, password);
    }
}

export default new SplashScreen();
