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

    setAddRecipient = async (recipient: string) => {
        await this.addRecipientField.setValue(recipient);
        await browser.pause(1000);
        await $(SELECTORS.RETURN_BUTTON).click()
    }

    setSubject = async (subject: string) => {
        await ElementHelper.waitClickAndType(await this.subjectField, subject);
    }

    setComposeSecurityMessage = async (message: string) => {
        await this.composeSecurityMesage.setValue(message);
    }

    filledSubject = async (subject: string) => {
        const selector = `**/XCUIElementTypeTextField[\`value == "${subject}"\`]`;
        return await $(`-ios class chain:${selector}`);
    }

    composeEmail = async (recipient: string, subject: string, message: string) => {
        await this.setAddRecipient(recipient);
        await this.setSubject(subject);
        await this.setComposeSecurityMessage(message);
    }

    setAddRecipientByName = async (name: string, email: string) => {
        await this.addRecipientField.setValue(name);
        const selector = `~${email}`;
        await $(selector).waitForDisplayed();
        await $(selector).click();
    }

    checkFilledComposeEmailInfo = async (recipient: string, subject: string, message: string) => {
        expect(this.composeSecurityMesage).toHaveText(message);
        const element = await this.filledSubject(subject);
        await element.waitForDisplayed();
        await this.checkAddedRecipient(recipient);
    }

    checkAddedRecipient = async (recipient: string) => {
        expect(await this.addedRecipientEmail).toHaveAttribute('value', `  ${recipient}  `);
    }

    clickBackButton = async () => {
        await ElementHelper.waitAndClick(await this.backButton);
    }
}

export default new NewMessageScreen();
