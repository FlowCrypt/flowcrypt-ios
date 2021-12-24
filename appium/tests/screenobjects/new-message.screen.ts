import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  ADD_RECIPIENT_FIELD: '~recipientTextField',
  SUBJECT_FIELD: '~subjectTextField',
  COMPOSE_SECURITY_MESSAGE: '~messageTextView',
  RECIPIENTS_LIST: '~recipientsList',
  ADDED_RECIPIENT: '-ios class chain:**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther' +
    '/XCUIElementTypeOther/XCUIElementTypeOther[1]/XCUIElementTypeOther/XCUIElementTypeTable' +
    '/XCUIElementTypeCell[1]/XCUIElementTypeOther/XCUIElementTypeCollectionView/XCUIElementTypeCell' +
    '/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeStaticText', //it works only with this selector
  PASSWORD_CELL: '~aid-message-password-cell',
  ATTACHMENT_CELL: '~aid-attachment-cell-0',
  ATTACHMENT_NAME_LABEL: '~aid-attachment-title-label-0',
  DELETE_ATTACHMENT_BUTTON: '~aid-attachment-delete-button-0',
  RETURN_BUTTON: '~Return',
  SET_PASSWORD_BUTTON: '~Set',
  CANCEL_BUTTON: '~Cancel',
  BACK_BUTTON: '~aid-back-button',
  SEND_BUTTON: '~aid-compose-send',
  MESSAGE_PASSWORD_MODAL: '~aid-message-password-modal',
  MESSAGE_PASSWORD_TEXTFIELD: '~aid-message-password-textfield',
  ALERT: "-ios predicate string:type == 'XCUIElementTypeAlert'"
};

class NewMessageScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.ADD_RECIPIENT_FIELD);
  }

  get addRecipientField() {
    return $(SELECTORS.ADD_RECIPIENT_FIELD);
  }

  get subjectField() {
    return $(SELECTORS.SUBJECT_FIELD);
  }

  get composeSecurityMessage() {
    return $(SELECTORS.COMPOSE_SECURITY_MESSAGE);
  }

  get recipientsList() {
    return $(SELECTORS.RECIPIENTS_LIST);
  }

  get addedRecipientEmail() {
    return $(SELECTORS.ADDED_RECIPIENT);
  }

  get attachmentCell() {
    return $(SELECTORS.ATTACHMENT_CELL);
  }

  get attachmentNameLabel() {
    return $(SELECTORS.ATTACHMENT_NAME_LABEL);
  }

  get deleteAttachmentButton() {
    return $(SELECTORS.DELETE_ATTACHMENT_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON);
  }

  get sendButton() {
    return $(SELECTORS.SEND_BUTTON);
  }

  get passwordCell() {
    return $(SELECTORS.PASSWORD_CELL);
  }

  get passwordModal() {
    return $(SELECTORS.MESSAGE_PASSWORD_MODAL);
  }

  get currentModal() {
    return $(SELECTORS.ALERT);
  }

  get passwordTextField() {
    return $(SELECTORS.MESSAGE_PASSWORD_TEXTFIELD);
  }

  get setPasswordButton() {
    return $(SELECTORS.SET_PASSWORD_BUTTON);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BUTTON);
  }

  setAddRecipient = async (recipient: string) => {
    await (await this.addRecipientField).setValue(recipient);
    await browser.pause(500);
    await (await $(SELECTORS.RETURN_BUTTON)).click()
  };

  setSubject = async (subject: string) => {
    await browser.pause(500);
    await ElementHelper.waitClickAndType(await this.subjectField, subject);
  };

  setComposeSecurityMessage = async (message: string) => {
    await browser.pause(500);
    await (await this.composeSecurityMessage).setValue(message);
  };

  filledSubject = async (subject: string) => {
    const selector = `**/XCUIElementTypeTextField[\`value == "${subject}"\`]`;
    return await $(`-ios class chain:${selector}`);
  };

  composeEmail = async (recipient: string, subject: string, message: string) => {
    await this.setAddRecipient(recipient);
    await this.setSubject(subject);
    await this.setComposeSecurityMessage(message);
  };

  setAddRecipientByName = async (name: string, email: string) => {
    await browser.pause(500); // stability fix for transition animation
    await (await this.addRecipientField).setValue(name);
    await ElementHelper.waitAndClick(await $(`~${email}`));
  };

  checkFilledComposeEmailInfo = async (recipient: string, subject: string, message: string, attachmentName?: string) => {
    expect(this.composeSecurityMessage).toHaveTextContaining(message);

    const element = await this.filledSubject(subject);
    await element.waitForDisplayed();

    if (recipient.length === 0) {
      await this.checkEmptyRecipientsList();
    } else {
      await this.checkAddedRecipient(recipient);
    }

    if (attachmentName !== undefined) {
      await this.checkAddedAttachment(attachmentName);
    }
  };

  checkRecipientsTextFieldIsInvisible = async () => {
    await ElementHelper.waitElementInvisible(await this.addRecipientField);
  }

  checkEmptyRecipientsList = async () => {
    const list = await this.recipientsList;
    const listText = await list.getText();
    expect(listText.length).toEqual(0);
  }

  checkAddedRecipient = async (recipient: string) => {
    const addedRecipientEl = await this.addedRecipientEmail;
    const value = await addedRecipientEl.getValue();
    expect(value).toEqual(`  ${recipient}  `);
  }

  checkAddedRecipientColor = async (recipient: string, order: number, color: string) => {
    const addedRecipientEl = await $(`~aid-to-${order}-${color}`);
    const name = await addedRecipientEl.getValue();
    expect(name).toEqual(`  ${recipient}  `);
  }

  checkAddedAttachment = async (name: string) => {
    await (await this.deleteAttachmentButton).waitForDisplayed();
    const label = await this.attachmentNameLabel;
    const value = await label.getValue();
    expect(value).toEqual(name);
  }

  deleteAttachment = async () => {
    await ElementHelper.waitAndClick(await this.deleteAttachmentButton);
    await ElementHelper.waitElementInvisible(await this.attachmentCell);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickSendButton = async () => {
    await ElementHelper.waitAndClick(await this.sendButton);
  }

  clickSetPasswordButton = async () => {
    await ElementHelper.waitAndClick(await this.setPasswordButton);
  }

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  }

  checkPasswordCell = async (text: string) => {
    await ElementHelper.checkStaticText(await this.passwordCell, text);
  }

  clickPasswordCell = async () => {
    await ElementHelper.waitAndClick(await this.passwordCell);
  }

  setMessagePassword = async (password: string) => {
    await (await this.passwordTextField).setValue(password);
    await this.clickSetPasswordButton();
  }
}

export default new NewMessageScreen();
