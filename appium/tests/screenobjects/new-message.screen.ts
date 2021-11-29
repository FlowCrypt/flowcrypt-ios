import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  ADD_RECIPIENT_FIELD: '-ios class chain:**/XCUIElementTypeTextField[`value == "Add Recipient"`]',
  SUBJECT_FIELD: '-ios class chain:**/XCUIElementTypeTextField[`value == "Subject"`]',
  COMPOSE_SECURITY_MESSAGE: '-ios predicate string:type == "XCUIElementTypeTextView"',
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
  ERROR_HEADER: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Error"`]',
  OK_BUTTON: '~OK'
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

  get errorHeader() {
    return $(SELECTORS.ERROR_HEADER)
  }

  get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  setAddRecipient = async (recipient: string) => {
    await (await this.addRecipientField).setValue(recipient);
    await browser.pause(1000);
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

  checkError = async (errorText: string) => {
    const message = '-ios class chain:**/XCUIElementTypeAlert/XCUIElementTypeOther/XCUIElementTypeOther/' +
      'XCUIElementTypeOther[2]/XCUIElementTypeScrollView[1]/XCUIElementTypeOther[1]/XCUIElementTypeStaticText[2]';//it works only with this selector
    await expect(await this.errorHeader).toBeDisplayed();
    await expect(await $(message)).toHaveAttribute('value', `${errorText}`);
    await expect(await this.okButton).toBeDisplayed();
  }

  clickOkButtonOnError = async () => {
    await ElementHelper.waitAndClick(await this.okButton)
  }
}

export default new NewMessageScreen();
