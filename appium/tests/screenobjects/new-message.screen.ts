import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
    ADD_RECIPIENT_FIELD: '-ios class chain:**/XCUIElementTypeTextField[`value == "Add Recipient"`]',
    SUBJECT_FIELD: '-ios class chain:**/XCUIElementTypeTextField[`value == "Subject"`]',
    COMPOSE_SECURITY_MESSAGE: '-ios predicate string:type == "XCUIElementTypeTextView"',
    ADDED_RECIPIENT: '-ios class chain:**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther' +
        '/XCUIElementTypeOther/XCUIElementTypeOther[1]/XCUIElementTypeOther/XCUIElementTypeTable' +
        '/XCUIElementTypeCell[1]/XCUIElementTypeOther/XCUIElementTypeCollectionView/XCUIElementTypeCell' +
        '/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeStaticText',//it works only with this selector
    RETURN_BUTTON: '~Return',
    BACK_BUTTON: '~arrow left c',
};

class NewMessageScreen extends BaseScreen {
    constructor () {
        super(SELECTORS.ADD_RECIPIENT_FIELD);
    }

    get addRecipientField () {
        return $(SELECTORS.ADD_RECIPIENT_FIELD);
    }

    get subjectField () {
        return $(SELECTORS.SUBJECT_FIELD);
    }

    get composeSecurityMesage () {
        return $(SELECTORS.COMPOSE_SECURITY_MESSAGE)
    }

    get addedRecipientEmail () {
        return $(SELECTORS.ADDED_RECIPIENT);
    }

    get backButton () {
        return $(SELECTORS.BACK_BUTTON);
    }

    setAddRecipient(recipient) {
        this.addRecipientField.setValue(recipient);
        browser.pause(1000);
        $(SELECTORS.RETURN_BUTTON).click()
    }

    setSubject(subject) {
        ElementHelper.waitClickAndType(this.subjectField, subject);
    }

    setComposeSecurityMessage(message) {
        this.composeSecurityMesage.setValue(message);
    }

    filledSubject(subject) {
        const selector = `**/XCUIElementTypeTextField[\`value == "${subject}"\`]`;
        return $(`-ios class chain:${selector}`);
    }

    composeEmail(recipient, subject, message) {
        this.setAddRecipient(recipient);
        this.setSubject(subject);
        this.setComposeSecurityMessage(message);
    }

    setAddRecipientByName(name, email) {
        this.addRecipientField.setValue(name);
        const selector = `~${email}`;
        $(selector).waitForDisplayed();
        $(selector).click();
    }

    checkFilledComposeEmailInfo(recipient, subject, message) {
        expect(this.composeSecurityMesage).toHaveText(message);
        this.filledSubject(subject).waitForDisplayed();
        this.checkAddedRecipient(recipient);
    }

    checkAddedRecipient(recipient)  {
        expect(this.addedRecipientEmail).toHaveAttribute('value', `  ${recipient}  `);
    }

    clickBackButton () {
        ElementHelper.waitAndClick(this.backButton);
    }
}

export default new NewMessageScreen();
