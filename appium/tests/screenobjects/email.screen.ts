import BaseScreen from './base.screen';
import { CommonData } from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BTN: '~arrow left c',
  ENTER_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
  OK_BUTTON: '~Ok',
  WRONG_PASS_PHRASE_MESSAGE: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Wrong pass phrase, please try again"`]',
  DOWNLOAD_ATTACHMENT_BUTTON: '~attachmentDownloadButton0',
  REPLY_BUTTON: '~replyButton',
  RECIPIENTS_BUTTON: '~messageRecipientButton',
  RECIPIENTS_TO_LABEL: '~toLabel0',
  RECIPIENTS_CC_LABEL: '~ccLabel0',
  RECIPIENTS_BCC_LABEL: '~bcLabel0',
  MENU_BUTTON: '~messageMenuButton',
  FORWARD_BUTTON: '~Forward',
  DELETE_BUTTON: '~Delete',
  CONFIRM_DELETING: '~OK',
  SENDER_EMAIL: '~messageSenderLabel',
  ENCRYPTION_BADGE: '~encryptionBadge',
  SIGNATURE_BADGE: '~signatureBadge'
};


class EmailScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN)
  }

  get enterPassPhraseField() {
    return $(SELECTORS.ENTER_PASS_PHRASE_FIELD)
  }

  get okButton() {
    return $(SELECTORS.OK_BUTTON)
  }

  get wrongPassPhraseMessage() {
    return $(SELECTORS.WRONG_PASS_PHRASE_MESSAGE)
  }

  get downloadAttachmentButton() {
    return $(SELECTORS.DOWNLOAD_ATTACHMENT_BUTTON);
  }

  get replyButton() {
    return $(SELECTORS.REPLY_BUTTON);
  }

  get recipientsButton() {
    return $(SELECTORS.RECIPIENTS_BUTTON);
  }

  get recipientsToLabel() {
    return $(SELECTORS.RECIPIENTS_TO_LABEL);
  }

  get recipientsCcLabel() {
    return $(SELECTORS.RECIPIENTS_TO_LABEL);
  }

  get recipientsBccLabel() {
    return $(SELECTORS.RECIPIENTS_TO_LABEL);
  }

  get menuButton() {
    return $(SELECTORS.MENU_BUTTON);
  }

  get forwardButton() {
    return $(SELECTORS.FORWARD_BUTTON);
  }

  get deleteButton() {
    return $(SELECTORS.DELETE_BUTTON)
  }

  get confirmDeletingButton() {
    return $(SELECTORS.CONFIRM_DELETING)
  }

  get senderEmail() {
    return $(SELECTORS.SENDER_EMAIL);
  }

  get encryptionBadge() {
    return $(SELECTORS.ENCRYPTION_BADGE);
  }

  get signatureBadge() {
    return $(SELECTORS.SIGNATURE_BADGE);
  }

  checkEmailAddress = async (email: string) => {
    await ElementHelper.checkStaticText(await this.senderEmail, email);
  }

  checkEmailSubject = async (subject: string) => {
    const selector = `~${subject}`;
    await (await $(selector)).waitForDisplayed();
  }

  checkEmailText = async (text: string) => {
    const selector = `~${text}`;
    await (await $(selector)).waitForDisplayed();
  }

  checkOpenedEmail = async (email: string, subject: string, text: string) => {
    await (await this.backButton).waitForDisplayed();
    await this.checkEmailAddress(email);
    await this.checkEmailSubject(subject);
    await this.checkEmailText(text);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickOkButton = async () => {
    await ElementHelper.waitAndClick(await this.okButton);
  }

  enterPassPhrase = async (text: string = CommonData.account.passPhrase) => {
    await (await this.enterPassPhraseField).setValue(text);
  }

  checkWrongPassPhraseErrorMessage = async () => {
    await (await this.wrongPassPhraseMessage).waitForDisplayed();
  }

  attachmentName = async (name: string) => {
    const selector = `-ios class chain:**/XCUIElementTypeStaticText[\`label == "${name}"\`]`;
    return $(selector);
  }

  checkAttachment = async (name: string) => {
    await (await this.downloadAttachmentButton).waitForDisplayed();
    const element = await this.attachmentName(name);
    await element.waitForDisplayed();
  }

  clickOnDownloadButton = async () => {
    await ElementHelper.waitAndClick(await this.downloadAttachmentButton);
  }

  clickReplyButton = async () => {
    await ElementHelper.waitAndClick(await this.replyButton);
  }

  clickRecipientsButton =async () => {
    await ElementHelper.waitAndClick(await this.recipientsButton);
  }

  clickMenuButton = async () => {
    await ElementHelper.waitAndClick(await this.menuButton);
  }

  clickForwardButton = async () => {
    await ElementHelper.waitAndClick(await this.forwardButton);
  }

  clickDeleteButton = async () => {
    await ElementHelper.waitAndClick(await this.deleteButton);
  }

  confirmDelete = async () => {
    await ElementHelper.waitAndClick(await this.confirmDeletingButton);
  }

  checkRecipientsButton = async (value: string) => {
    await ElementHelper.checkStaticText(await this.recipientsButton, value);
  }

  checkRecipientsList = async (to: string, cc: string, bcc: string) => {
    await ElementHelper.checkStaticText(await this.recipientsToLabel, to);
    await ElementHelper.checkStaticText(await this.recipientsCcLabel, cc);
    await ElementHelper.checkStaticText(await this.recipientsBccLabel, bcc);
  }

  checkEncryptionBadge = async (value: string) => {
    await ElementHelper.checkStaticText(await this.encryptionBadge, value);
  }

  checkSignatureBadge = async (value: string) => {
    await ElementHelper.checkStaticText(await this.signatureBadge, value);
  }
}

export default new EmailScreen();
