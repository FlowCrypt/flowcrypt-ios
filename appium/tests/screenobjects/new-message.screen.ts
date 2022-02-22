import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  TOGGLE_RECIPIENTS_BUTTON: '~aid-recipients-toggle-button',
  SUBJECT_FIELD: '~aid-subject-text-field',
  COMPOSE_SECURITY_MESSAGE: '~aid-message-text-view',
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
    super(SELECTORS.RECIPIENTS_LIST);
  }

  get toggleRecipientsButton() {
    return $(SELECTORS.TOGGLE_RECIPIENTS_BUTTON);
  }

  get subjectField() {
    return $(SELECTORS.SUBJECT_FIELD);
  }

  get composeSecurityMessage() {
    return $(SELECTORS.COMPOSE_SECURITY_MESSAGE);
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

  getRecipientsList = async (type: string) => {
    return $(`~aid-recipients-list-${type}`);
  }

  getRecipientsTextField = async (type: string) => {
    return $(`~aid-recipients-text-field-${type}`);
  }

  setAddRecipient = async (recipient?: string, type = 'to') => {
    if (recipient) {
      await (await this.getRecipientsTextField(type)).setValue(recipient);
      await browser.pause(500);
      await (await $(SELECTORS.RETURN_BUTTON)).click();
    }
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

  composeEmail = async (recipient: string, subject: string, message: string, cc?: string, bcc?: string) => {
    await this.setAddRecipient(recipient);
    if (cc || bcc) {
      await this.clickToggleRecipientsButton();
      await this.setAddRecipient(cc, 'cc');
      await this.setAddRecipient(bcc, 'bcc');
    }
    await this.setComposeSecurityMessage(message);
    await this.setSubject(subject);
  };

  setAddRecipientByName = async (name: string, email: string, type = 'to') => {
    await browser.pause(500); // stability fix for transition animation
    await (await this.getRecipientsTextField(type)).setValue(name);
    await ElementHelper.waitAndClick(await $(`~${email}`));
  };

  checkFilledComposeEmailInfo = async (recipients: string[], subject: string, message: string, attachmentName?: string, cc?: string[], bcc?: string[]) => {
    expect(await this.composeSecurityMessage).toHaveTextContaining(message);
    
    const element = await this.filledSubject(subject);
    await element.waitForDisplayed();

    await this.checkRecipientsList(recipients);

    if (cc) {
      await this.checkRecipientsList(cc, 'cc');
    }

    if (bcc) {
      await this.checkRecipientsList(bcc, 'bcc');
    }

    if (attachmentName !== undefined) {
      await this.checkAddedAttachment(attachmentName);
    }
  };

  checkRecipientsTextFieldIsInvisible = async (type = 'to') => {
    await ElementHelper.waitElementInvisible(await this.getRecipientsTextField(type));
  }

  checkRecipientsList = async(recipients: string[], type = 'to') => {
    if (recipients.length === 0) {
      await ElementHelper.waitElementInvisible(await $(`~aid-${type}-0-label`));
    } else {
      for (const [index, recipient] of recipients.entries()) {
        await this.checkAddedRecipient(recipient, index, type);
      }
    }
  }

  checkAddedRecipient = async (recipient: string, order = 0, type = 'to') => {
    const recipientCell = await $(`~aid-${type}-${order}-label`);
    await ElementHelper.waitElementVisible(recipientCell);
    const name = await recipientCell.getValue();
    expect(name).toEqual(`  ${recipient}  `);
  }

  checkAddedRecipientColor = async (recipient: string, order: number, color: string, type = 'to') => {
    const addedRecipientEl = await $(`~aid-${type}-${order}-${color}`);
    await ElementHelper.waitElementVisible(addedRecipientEl);
    await this.checkAddedRecipient(recipient, order);
  }

  deleteAddedRecipient = async (order: number, type = 'to') => {
    const addedRecipientEl = await $(`~aid-${type}-${order}-label`);
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

  clickToggleRecipientsButton =async () => {
    await ElementHelper.waitAndClick(await this.toggleRecipientsButton);
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
