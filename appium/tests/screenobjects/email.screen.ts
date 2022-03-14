import BaseScreen from './base.screen';
import { CommonData } from "../data";
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  ENTER_PASS_PHRASE_FIELD: '-ios class chain:**/XCUIElementTypeSecureTextField',
  OK_BUTTON: '~Ok',
  WRONG_PASS_PHRASE_MESSAGE: '-ios class chain:**/XCUIElementTypeStaticText[`label == "Wrong pass phrase, please try again"`]',
  ATTACHMENT_CELL: '~aid-attachment-cell-0',
  ATTACHMENT_TITLE: '~aid-attachment-title-label-0',
  REPLY_BUTTON: '~aid-reply-button',
  RECIPIENTS_BUTTON: '~aid-message-recipients-tappable-area',
  RECIPIENTS_TO_LABEL: '~toLabel0',
  RECIPIENTS_CC_LABEL: '~ccLabel0',
  RECIPIENTS_BCC_LABEL: '~bccLabel0',
  MENU_BUTTON: '~aid-message-menu-button',
  FORWARD_BUTTON: '~Forward',
  REPLY_ALL_BUTTON: '~Reply all',
  DELETE_BUTTON: '~Delete',
  DOWNLOAD_BUTTON: '~Download',
  CANCEL_BUTTON: '~Cancel',
  CONFIRM_DELETING: '~Ok',
  SENDER_EMAIL: '~aid-message-sender-label',
  ENCRYPTION_BADGE: '~aid-encryption-badge',
  SIGNATURE_BADGE: '~aid-signature-badge',
  ATTACHMENT_TEXT_VIEW: '~aid-attachment-text-view'
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

  get attachmentCell() {
    return $(SELECTORS.ATTACHMENT_CELL);
  }

  get attachmentTitle() {
    return $(SELECTORS.ATTACHMENT_TITLE);
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
    return $(SELECTORS.RECIPIENTS_CC_LABEL);
  }

  get recipientsBccLabel() {
    return $(SELECTORS.RECIPIENTS_BCC_LABEL);
  }

  get menuButton() {
    return $(SELECTORS.MENU_BUTTON);
  }

  get forwardButton() {
    return $(SELECTORS.FORWARD_BUTTON);
  }

  get replyAllButton() {
    return $(SELECTORS.REPLY_ALL_BUTTON);
  }

  get deleteButton() {
    return $(SELECTORS.DELETE_BUTTON)
  }

  get confirmDeletingButton() {
    return $(SELECTORS.CONFIRM_DELETING)
  }

  get downloadButton() {
    return $(SELECTORS.DOWNLOAD_BUTTON);
  }

  get cancelButton() {
    return $(SELECTORS.CANCEL_BUTTON);
  }

  get encryptionBadge() {
    return $(SELECTORS.ENCRYPTION_BADGE);
  }

  get signatureBadge() {
    return $(SELECTORS.SIGNATURE_BADGE);
  }

  get attachmentTextView() {
    return $(SELECTORS.ATTACHMENT_TEXT_VIEW);
  }

  senderEmail = async (index = 0) =>{
      return $(`~aid-sender-${index}`)
  }

  checkEmailAddress = async (email: string, index = 0)=> {
    const element = await this.senderEmail(index);
    await (await element).waitForDisplayed();
    await expect(await (await element).getValue()).toEqual(email);
  }

  checkEmailSubject = async (subject: string) => {
    const selector = `~${subject}`;
    await (await $(selector)).waitForDisplayed();
  }

  checkEmailText = async (text: string, index = 0) => {
    const selector = `~aid-message-${index}`;
    await (await $(selector)).waitForDisplayed();
    console.log(await $(selector).getValue());

    await expect(await $(selector).getValue()).toContain(text)
  }

  checkOpenedEmail = async (email: string, subject: string, text: string) => {
    await this.checkEmailAddress(email);
    await this.checkEmailSubject(subject);
    await this.checkEmailText(text);
  }

  checkThreadMessage = async (email: string, subject: string, text: string, date: string, index = 0) => {
      await this.checkEmailSubject(subject);
      await this.checkEmailAddress(email, index);
      await this.clickExpandButtonByIndex(index);
      await this.checkEmailText(text, index);
      await this.checkDate(date, index);
  }

  clickExpandButtonByIndex = async (index: any) => {
    const element = (`~aid-expand-image-${index}`);
    if(await (await $(element)).isDisplayed()) {
      await ElementHelper.waitAndClick(await $(element));
    }
  }

  checkDate = async (date: string, index: any) => {
    const element = `~aid-date-${index}`;
    await (await $(element)).waitForDisplayed();
    await expect(await $(element).getValue()).toEqual(date)
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickOkButton = async () => {
    await ElementHelper.waitAndClick(await this.okButton);
  }

  clickDownloadButton = async () => {
    await ElementHelper.waitAndClick(await  this.downloadButton);
  }

  enterPassPhrase = async (text: string = CommonData.account.passPhrase) => {
    await (await this.enterPassPhraseField).setValue(text);
  }

  checkWrongPassPhraseErrorMessage = async () => {
    await (await this.wrongPassPhraseMessage).waitForDisplayed();
  }

  checkAttachment = async (name: string) => {
    await (await this.attachmentCell).waitForDisplayed();
    await ElementHelper.checkStaticText(await this.attachmentTitle, name);
  }

  clickOnAttachmentCell = async () => {
    await ElementHelper.waitAndClick(await this.attachmentCell);
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

  clickReplyAllButton = async () => {
    await ElementHelper.waitAndClick(await this.replyAllButton);
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

  checkAttachmentTextView = async (value: string) => {
    const el = await this.attachmentTextView;
    expect(el).toHaveValueContaining(value);
  }
}

export default new EmailScreen();
