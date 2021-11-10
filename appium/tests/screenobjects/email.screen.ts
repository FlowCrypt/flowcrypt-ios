import BaseScreen from './base.screen';
import {CommonData} from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    BACK_BTN: '~arrow left c',
    ENTER_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
    OK_BUTTON: '~Ok',
    WRONG_PASS_PHRASE_MESSAGE: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Wrong pass phrase, please try again"`]',
    SAVE_BUTTON: '~Save',
    DOWNLOAD_ATTACHMENT_BUTTON: '-ios class chain:**/XCUIElementTypeCell[4]/XCUIElementTypeOther/XCUIElementTypeButton',
};


class EmailScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.BACK_BTN);
    }

    get backButton() {
        return $(SELECTORS.BACK_BTN)
    }

    get enterPassPhraseField() {
        return $(SELECTORS.ENTER_PASS_PHRASE_FIELD)
    }

    get okButton () {
        return $(SELECTORS.OK_BUTTON)
    }

    get wrongPassPhraseMessage () {
        return $(SELECTORS.WRONG_PASS_PHRASE_MESSAGE)
    }

    get saveButton() {
        return $(SELECTORS.SAVE_BUTTON)
    }

    get downloadAttachmentButton() {
        return $(SELECTORS.DOWNLOAD_ATTACHMENT_BUTTON);
    }

    checkEmailAddress (email) {
        const selector = `-ios class chain:**/XCUIElementTypeTextView[\`label == "${email}"\`]`;
        $(selector).waitForDisplayed();
    }

    checkEmailSubject (subject) {
        const selector = `~${subject}`;
        $(selector).waitForDisplayed();
    }

    checkEmailText (text) {
        const selector = `~${text}`;
        $(selector).waitForDisplayed();
    }

    checkOpenedEmail (email, subject, text) {
        this.backButton.waitForDisplayed();
        this.checkEmailAddress(email);
        this.checkEmailSubject(subject);
        this.checkEmailText(text);
    }

    clickBackButton () {
        ElementHelper.waitAndClick(this.backButton);
    }

    clickOkButton() {
        ElementHelper.waitAndClick(this.okButton);
    }

    enterPassPhrase (text: string = CommonData.account.passPhrase) {
        this.enterPassPhraseField.setValue(text);
    };

    checkWrongPassPhraseErrorMessage() {
        this.wrongPassPhraseMessage.waitForDisplayed();
    }

    clickSaveButton() {
        ElementHelper.waitAndClick(this.saveButton);
    }

    attachmentName(name) {
        const selector = `-ios class chain:**/XCUIElementTypeStaticText[\`label == "${name}"\`]`;
        return $(selector);
    }

    checkAttachment(name) {
        this.downloadAttachmentButton.waitForDisplayed();
        this.attachmentName(name).waitForDisplayed();
    }

    clickOnDownloadButton() {
        ElementHelper.waitAndClick(this.downloadAttachmentButton);
    }
}

export default new EmailScreen();
