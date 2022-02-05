import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  ADD_RECIPIENT_FIELD: '~aid-recipient-text-field',
  SUBJECT_FIELD: '~subjectTextField',
  COMPOSE_SECURITY_MESSAGE: '~messageTextView',
  RECIPIENTS_LIST: '~aid-recipients-list',
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
    await ElementHelper.waitClickAndType(await this.composeSecurityMessage, message);
  };

  filledSubject = async (subject: string) => {
    const selector = `**/XCUIElementTypeTextField[\`value == "${subject}"\`]`;
    return await $(`-ios class chain:${selector}`);
  };

  composeEmail = async (recipient: string, subject: string, message: string) => {
    await this.setAddRecipient(recipient);
    await this.setComposeSecurityMessage(message);
    await this.setSubject(subject);
  };

  setAddRecipientByName = async (name: string, email: string) => {
    await browser.pause(500); // stability fix for transition animation
    await (await this.addRecipientField).setValue(name);
    await ElementHelper.waitAndClick(await $(`~${email}`));
  };

  checkFilledComposeEmailInfo = async (recipients: string[], subject: string, message: string, attachmentName?: string) => {
    expect(this.composeSecurityMessage).toHaveTextContaining(message);

    const element = await this.filledSubject(subject);
    await element.waitForDisplayed();

    await this.checkRecipientsList(recipients);

    if (attachmentName !== undefined) {
      await this.checkAddedAttachment(attachmentName);
    }
  };

  checkRecipientsTextFieldIsInvisible = async () => {
    await ElementHelper.waitElementInvisible(await this.addRecipientField);
  }

  checkRecipientsList = async(recipients: string[]) => {
    if (recipients.length === 0) {
      await ElementHelper.waitElementInvisible(await $(`~aid-to-0-label`));
    } else {
      for (const [index, recipient] of recipients.entries()) {
        await this.checkAddedRecipient(recipient, index);
      }
    }
  }

  checkAddedRecipient = async (recipient: string, order = 0) => {
    const recipientCell = await $(`~aid-to-${order}-label`);
    const name = await recipientCell.getValue();
    expect(name).toEqual(`  ${recipient}  `);
  }

  checkAddedRecipientColor = async (recipient: string, order: number, color: string) => {
    const addedRecipientEl = await $(`~aid-to-${order}-${color}`);
    await ElementHelper.waitElementVisible(addedRecipientEl);
    await this.checkAddedRecipient(recipient, order);
  }

  deleteAddedRecipient = async (order: number) => {
    const addedRecipientEl = await $(`~aid-to-${order}-label`);
    await ElementHelper.waitAndClick(addedRecipientEl);
    await driver.sendKeys(['\b']); // backspace
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

  checkSetPasswordButton = async(isEnabled: boolean) => {
    const el = await this.setPasswordButton;
    expect(await el.isEnabled()).toBe(isEnabled);
  }

  checkPasswordCell = async (text: string) => {
    await ElementHelper.waitElementVisible(await this.passwordCell);
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
