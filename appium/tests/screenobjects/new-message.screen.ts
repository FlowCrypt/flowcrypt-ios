import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import TouchHelper from "../helpers/TouchHelper";

const SELECTORS = {
  RECIPIENT_LIST_LABEL: '~aid-recipient-list-text',
  TOGGLE_RECIPIENTS_BUTTON: '~aid-recipients-toggle-button',
  TOGGLE_FROM_BUTTON: '~aid-from-toggle-button',
  FROM_VALUE_NODE: '~aid-from-value-node',
  SUBJECT_FIELD: '~aid-subject-text-field',
  COMPOSE_SECURITY_MESSAGE: '~aid-message-text-view',
  RECIPIENTS_LIST: '~aid-recipients-list',
  PASSWORD_CELL: '~aid-message-password-cell',
  ATTACHMENT_CELL: '~aid-attachment-cell-0',
  ATTACHMENT_NAME_LABEL: '~aid-attachment-title-label-0',
  DELETE_ATTACHMENT_BUTTON: '~aid-attachment-delete-button-0',
  RETURN_BUTTON: '~Return',
  SET_PASSWORD_BUTTON: '~Set',
  CANCEL_BUTTON: '~aid-cancel-button',
  BACK_BUTTON: '~aid-back-button',
  DELETE_BUTTON: '~aid-compose-delete',
  SEND_BUTTON: '~aid-compose-send',
  SEND_PLAIN_MESSAGE_BUTTON: '~aid-compose-send-plain',
  CONFIRM_DELETING: '~Delete',
  MESSAGE_PASSPHRASE_TEXTFIELD: '~aid-message-passphrase-textfield',
  MESSAGE_PASSWORD_TEXTFIELD: '~aid-message-password-textfield',
  ALERT: "-ios predicate string:type == 'XCUIElementTypeAlert'",
  RECIPIENT_POPUP_EMAIL_NODE: '~aid-recipient-popup-email-node',
  RECIPIENT_POPUP_NAME_NODE: '~aid-recipient-popup-name-node',
  RECIPIENT_POPUP_COPY_BUTTON: '~aid-recipient-popup-copy-button',
  RECIPIENT_POPUP_REMOVE_BUTTON: '~aid-recipient-popup-remove-button',
  RECIPIENT_POPUP_EDIT_BUTTON: '~aid-recipient-popup-edit-button',
  RECIPIENT_SPINNER: '~aid-recipient-spinner'
};

interface ComposeEmailInfo {
  recipients: string[];
  subject: string;
  message: string;
  attachmentName?: string;
  cc?: string[];
  bcc?: string[];
}

class NewMessageScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.RECIPIENTS_LIST);
  }

  get toggleRecipientsButton() {
    return $(SELECTORS.TOGGLE_RECIPIENTS_BUTTON);
  }

  get toggleFromButton() {
    return $(SELECTORS.TOGGLE_FROM_BUTTON);
  }

  get fromValueNode() {
    return $(SELECTORS.FROM_VALUE_NODE);
  }

  get recipientListLabel() {
    return $(SELECTORS.RECIPIENT_LIST_LABEL);
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

  get deleteButton() {
    return $(SELECTORS.DELETE_BUTTON);
  }

  get sendButton() {
    return $(SELECTORS.SEND_BUTTON);
  }

  get sendPlainMessageButton() {
    return $(SELECTORS.SEND_PLAIN_MESSAGE_BUTTON);
  }

  get confirmDeletingButton() {
    return $(SELECTORS.CONFIRM_DELETING)
  }

  get passwordCell() {
    return $(SELECTORS.PASSWORD_CELL);
  }

  get currentModal() {
    return $(SELECTORS.ALERT);
  }

  get passphraseTextField() {
    return $(SELECTORS.MESSAGE_PASSPHRASE_TEXTFIELD);
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

  get recipientPopupEmailNode() {
    return $(SELECTORS.RECIPIENT_POPUP_EMAIL_NODE);
  }

  get recipientPopupNameNode() {
    return $(SELECTORS.RECIPIENT_POPUP_NAME_NODE);
  }

  get recipientPopupCopyButton() {
    return $(SELECTORS.RECIPIENT_POPUP_COPY_BUTTON);
  }

  get recipientPopupRemoveButton() {
    return $(SELECTORS.RECIPIENT_POPUP_REMOVE_BUTTON);
  }

  get recipientPopupEditButton() {
    return $(SELECTORS.RECIPIENT_POPUP_EDIT_BUTTON);
  }

  get recipientSpinner() {
    return $(SELECTORS.RECIPIENT_SPINNER);
  }

  getRecipientsTextField = async (type: string) => {
    return $(`~aid-recipients-text-field-${type}`);
  }

  deleteEnteredRecipient = async (recipient: string, type = 'to') => {
    const textFieldEl = await this.getRecipientsTextField(type);
    await ElementHelper.waitAndClick(textFieldEl);
    const keys = Array(recipient.length).fill('\b');
    await driver.sendKeys(keys);
  }

  setAddRecipient = async (recipient?: string, type = 'to') => {
    if (recipient) {
      await browser.pause(500);
      await this.showRecipientInputIfNeeded();
      const textFieldEl = await this.getRecipientsTextField(type);
      await ElementHelper.waitElementVisible(textFieldEl);
      await textFieldEl.setValue(recipient);
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
    const el = await this.composeSecurityMessage;
    await ElementHelper.clearInput(el);
    await ElementHelper.waitClickAndType(el, message);
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
    await ElementHelper.waitElementInvisible(await this.recipientSpinner);
    await this.showRecipientLabelIfNeeded();
    await this.setComposeSecurityMessage(message);
    await this.setSubject(subject);
  };

  changeFromEmail = async (email: string) => {
    await this.showRecipientInputIfNeeded();
    await ElementHelper.waitAndClick(await this.toggleFromButton);
    await ElementHelper.waitAndClick(await $(`~aid-send-as-${email.replace(/@/, '-').replace(/\./g, '-')}`));
    await ElementHelper.checkStaticText(await this.fromValueNode, email);
  }

  checkRecipientLabel = async (recipientList: string[]) => {
    await this.showRecipientLabelIfNeeded();
    expect(await this.recipientListLabel.getValue()).toBe(recipientList.join(", "));
  }

  setAddRecipientByName = async (name: string, email: string, type = 'to') => {
    await browser.pause(500); // stability fix for transition animation
    await (await this.getRecipientsTextField(type)).setValue(name);
    await ElementHelper.waitAndClick(await $(`~${email}`));
  };

  checkFilledComposeEmailInfo = async (emailInfo: ComposeEmailInfo) => {
    const messageEl = await this.composeSecurityMessage;
    await ElementHelper.waitElementVisible(messageEl);
    const text = await messageEl.getText();
    expect(text.includes(emailInfo.message)).toBeTrue();

    const element = await this.filledSubject(emailInfo.subject);
    await element.waitForDisplayed();

    await ElementHelper.waitElementInvisible(await this.recipientSpinner);
    if (await this.recipientListLabel.isDisplayed()) {
      const allRecipients = [...emailInfo.recipients, ...emailInfo.cc ?? [], ...emailInfo.bcc ?? []];
      await this.checkRecipientLabel(allRecipients);
    } else {
      await this.checkRecipientsList(emailInfo.recipients);

      if (emailInfo.cc) {
        await this.checkRecipientsList(emailInfo.cc, 'cc');
      }

      if (emailInfo.bcc) {
        await this.checkRecipientsList(emailInfo.bcc, 'bcc');
      }

      if (emailInfo.attachmentName !== undefined) {
        await this.checkAddedAttachment(emailInfo.attachmentName);
      }
    }

  };

  checkRecipientsTextFieldIsInvisible = async (type = 'to') => {
    await ElementHelper.waitElementInvisible(await this.getRecipientsTextField(type));
  }

  showRecipientInputIfNeeded = async () => {
    if (await this.recipientListLabel.isDisplayed()) {
      await this.recipientListLabel.click();
    }
  }

  showRecipientLabelIfNeeded = async () => {
    if (!await this.recipientListLabel.isDisplayed()) {
      await this.subjectField.click();
      await ElementHelper.waitElementVisible(await this.recipientListLabel);
    }
  }

  checkRecipientsList = async (recipients: string[], type = 'to') => {
    await this.showRecipientInputIfNeeded();
    if (recipients.length === 0) {
      await ElementHelper.waitElementInvisible(await $(`~aid-${type}-0-label`));
    } else {
      for (const [index, recipient] of recipients.entries()) {
        await this.checkAddedRecipient(recipient, index, type);
      }
    }
  }

  checkAddedRecipient = async (recipient: string, order = 0, type = 'to') => {
    await this.showRecipientInputIfNeeded();
    const recipientCell = await $(`~aid-${type}-${order}-label`);
    await ElementHelper.waitForValue(recipientCell, `  ${recipient}  `);
  }

  getActiveElementId = async () => {
    await browser.pause(500);
    const activeElement = (await driver.getActiveElement()) as unknown as { ELEMENT: string };
    return activeElement.ELEMENT;
  }

  checkMessageFieldFocus = async () => {
    await ElementHelper.waitElementVisible(await this.recipientListLabel);
    const messageElementId = (await this.composeSecurityMessage).elementId;
    expect(messageElementId).toBe(await this.getActiveElementId());
  }

  checkRecipientTextFieldFocus = async () => {
    const toTextField = await this.getRecipientsTextField('to');
    await ElementHelper.waitElementVisible(toTextField);
    const toTextFieldActiveElementId = ((await toTextField.getActiveElement()) as unknown as { ELEMENT: string }).ELEMENT;
    const activeElementId = await this.getActiveElementId();
    expect(toTextFieldActiveElementId).toBe(activeElementId);
  }

  checkAddedRecipientColor = async (recipient: string, order: number, color: string, type = 'to') => {
    await this.showRecipientInputIfNeeded();
    const addedRecipientEl = await $(`~aid-${type}-${order}-${color}`);
    await ElementHelper.waitElementVisible(addedRecipientEl);
    await this.checkAddedRecipient(recipient, order);
  }

  deleteAddedRecipient = async (order: number, type = 'to') => {
    await this.showRecipientPopup(order, type);
    const addedRecipientEl = await $(`~aid-${type}-${order}-label`);
    await ElementHelper.waitAndClick(await this.recipientPopupRemoveButton);
    await ElementHelper.waitElementInvisible(addedRecipientEl);
  }

  deleteAddedRecipientWithBackspace = async (order: number, type = 'to') => {
    await this.showRecipientPopup(order, type);
    await driver.sendKeys(['\b']); // backspace
  }

  deleteAddedRecipientWithDoubleBackspace = async () => {
    await this.showRecipientInputIfNeeded();
    await driver.sendKeys(['\b']); // backspace
    await driver.sendKeys(['\b']); // backspace
  }

  checkCopyForAddedRecipient = async (email: string, order: number, type = 'to') => {
    await this.showRecipientPopup(order, type);
    await ElementHelper.waitAndClick(await this.recipientPopupCopyButton);
    const base64Encoded = Buffer.from(email).toString('base64');
    expect(await driver.getClipboard('plaintext')).toEqual(base64Encoded);
  }

  checkPopupRecipientInfo = async (email: string, order: number, type = 'to', name?: string) => {
    await this.showRecipientPopup(order, type);
    expect(await (await this.recipientPopupEmailNode).getValue()).toBe(email);
    if (name) {
      expect(await (await this.recipientPopupNameNode).getValue()).toBe(name);
    }
    await TouchHelper.tapScreen('centerRight');
  }

  showRecipientPopup = async (order: number, type = 'to') => {
    await browser.pause(300);
    await this.showRecipientInputIfNeeded();
    const addedRecipientEl = await $(`~aid-${type}-${order}-label`);
    await ElementHelper.waitAndClick(addedRecipientEl);
  }

  checkEditRecipient = async (order: number, type = 'to', recipient: string, recipientCount: number) => {
    await this.showRecipientInputIfNeeded();
    const addedRecipientEl = await $(`~aid-${type}-${order}-label`);
    await ElementHelper.waitAndClick(addedRecipientEl);
    await ElementHelper.waitAndClick(await this.recipientPopupEditButton);
    await browser.pause(1000); // Wait for added element to be deleted and text field to be set
    await (await $(SELECTORS.RETURN_BUTTON)).click();
    // Edited element will be placed at the end
    await this.checkAddedRecipient(recipient, recipientCount - 1, type);
  }

  checkAddedAttachment = async (name: string) => {
    await (await this.deleteAttachmentButton).waitForDisplayed();
    const label = await this.attachmentNameLabel;
    await ElementHelper.waitForValue(label, name);
  }

  checkRecipientEvaluationWhenTapOutside = async (type = 'to') => {
    const recipient = 'test.recipient.evaluation@example.com'
    await (await this.getRecipientsTextField(type)).setValue(recipient);
    await browser.pause(2000);
    await TouchHelper.tapScreen('centerCenter');
    await this.checkAddedRecipient(recipient, 0);
  }

  deleteAttachment = async () => {
    await ElementHelper.waitAndClick(await this.deleteAttachmentButton);
    await ElementHelper.waitElementInvisible(await this.attachmentCell);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickDeleteButton = async () => {
    await ElementHelper.waitAndClick(await this.deleteButton);
  }

  clickSendButton = async () => {
    await ElementHelper.waitAndClick(await this.sendButton);
  }

  clickSendPlainMessageButton = async () => {
    await ElementHelper.waitAndClick(await this.sendPlainMessageButton);
  }

  confirmDelete = async () => {
    await ElementHelper.waitAndClick(await this.confirmDeletingButton);
    await browser.pause(500);
  }

  clickToggleRecipientsButton = async () => {
    await browser.pause(500);
    await ElementHelper.waitAndClick(await this.toggleRecipientsButton);
  }

  clickSetPasswordButton = async () => {
    await ElementHelper.waitAndClick(await this.setPasswordButton);
  }

  clickCancelButton = async () => {
    await ElementHelper.waitAndClick(await this.cancelButton);
  }

  checkSetPasswordButton = async (isEnabled: boolean) => {
    const el = await this.setPasswordButton;
    expect(await el.isEnabled()).toBe(isEnabled);
  }

  checkPasswordCell = async (text: string) => {
    const el = await this.passwordCell;
    await ElementHelper.waitElementVisible(el);
    await ElementHelper.checkStaticText(el, text);
  }

  clickPasswordCell = async () => {
    await ElementHelper.waitAndClick(await this.passwordCell);
  }

  setMessagePassword = async (password: string) => {
    await (await this.passwordTextField).setValue(password);
    await this.clickSetPasswordButton();
  }

  clickComposeMessage = async () => {
    await ElementHelper.waitAndClick(await this.composeSecurityMessage);
  }

  addMessageText = async (text: string) => {
    const messageEl = await this.composeSecurityMessage;
    await messageEl.sendKeys([text]);
  }
}

export default new NewMessageScreen();
