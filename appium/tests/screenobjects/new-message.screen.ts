import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import TouchHelper from "../helpers/TouchHelper";

const SELECTORS = {
  RECIPIENT_LIST_LABEL: '~aid-recipient-list-text',
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
  ALERT: "-ios predicate string:type == 'XCUIElementTypeAlert'",
  RECIPIENT_POPUP_EMAIL_NODE: '~aid-recipient-popup-email-node',
  RECIPIENT_POPUP_NAME_NODE: '~aid-recipient-popup-name-node',
  RECIPIENT_POPUP_COPY_BUTTON: '~aid-recipient-popup-copy-button',
  RECIPIENT_POPUP_REMOVE_BUTTON: '~aid-recipient-popup-remove-button',
  RECIPIENT_POPUP_EDIT_BUTTON: '~aid-recipient-popup-edit-button'
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
    await ElementHelper.waitElementVisible(await this.composeSecurityMessage);
    expect(await this.composeSecurityMessage).toHaveTextContaining(emailInfo.message);

    const element = await this.filledSubject(emailInfo.subject);
    await element.waitForDisplayed();

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
    await ElementHelper.waitElementVisible(recipientCell);
    await ElementHelper.waitForValue(await recipientCell, `  ${recipient}  `);
  }

  getActiveElementId = async () => {
    await browser.pause(100);
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
    await this.showRecipientPopup(order, type)
    await driver.sendKeys(['\b']); // backspace
  }

  checkCopyForAddedRecipient = async (email: string, order: number, type = 'to') => {
    await this.showRecipientPopup(order, type);
    await ElementHelper.waitAndClick(await this.recipientPopupCopyButton);
    const base64Encoded = new Buffer(email).toString('base64');
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
    await ElementHelper.waitForValue(await label, name);
  }

  checkRecipientEvaluationWhenTapOutside = async (type = 'to') => {
    const recipient = 'test@gmail.com'
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

  clickSendButton = async () => {
    await ElementHelper.waitAndClick(await this.sendButton);
  }

  clickToggleRecipientsButton = async () => {
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
}

export default new NewMessageScreen();
