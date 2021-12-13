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
  ATTACHMENT_CELL: '~attachmentCell0',
  ATTACHMENT_NAME_LABEL: '~attachmentTitleLabel0',
  DELETE_ATTACHMENT_BUTTON: '~attachmentDeleteButton0',
  RETURN_BUTTON: '~Return',
  BACK_BUTTON: '~arrow left c',
  SEND_BUTTON: '~android send',
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

  setAddRecipient = async (recipient: string) => {
    await (await this.addRecipientField).setValue(recipient);
    await browser.pause(2000);
    await (await $(SELECTORS.RETURN_BUTTON)).click()
  };

  setSubject = async (subject: string) => {
    await ElementHelper.waitClickAndType(await this.subjectField, subject);
  };

  setComposeSecurityMessage = async (message: string) => {
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
  };

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
}

export default new NewMessageScreen();
