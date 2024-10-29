import BaseScreen from './base.screen';
import { CommonData } from '../data';
import ElementHelper from '../helpers/ElementHelper';
import WebView from '../helpers/WebView';

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  ENTER_PASS_PHRASE_FIELD: '~aid-message-passphrase-textfield',
  OK_BUTTON: '~aid-ok-button',
  ENTR_PASSPHRASE_TITLE_LABEL: '~aid-enter-passphrase-title-label',
  ATTACHMENT_CELL: '~aid-attachment-cell-0',
  ATTACHMENT_TITLE: '~aid-attachment-title-label-0',
  REPLY_BUTTON: '~aid-reply-button',
  RECIPIENTS_BUTTON: '~aid-message-recipients-tappable-area',
  RECIPIENTS_TO_LABEL: '~aid-to-0-label',
  RECIPIENTS_CC_LABEL: '~aid-cc-0-label',
  RECIPIENTS_BCC_LABEL: '~aid-bcc-0-label',
  MENU_BUTTON: '~aid-message-menu-button',
  ANTI_BRUTE_FORCE_INTRODUCE_LABEL: '~aid-anti-brute-force-introduce-label',
  FORWARD_BUTTON: '~aid-forward-button',
  REPLY_ALL_BUTTON: '~aid-reply-all-button',
  HELP_BUTTON: '~aid-help-button',
  ARCHIVE_BUTTON: '~aid-archive-button',
  MOVE_TO_INBOX_BUTTON: '~aid-move-to-inbox-button',
  DELETE_BUTTON: '~aid-delete-button',
  UNREAD_BUTTON: '~aid-unread-button',
  DOWNLOAD_BUTTON: '~aid-download-button',
  CONFIRM_DELETING: '~aid-confirm-button',
  SENDER_EMAIL: '~aid-message-sender-label',
  ENCRYPTION_BADGE: '~aid-encryption-badge',
  SIGNATURE_BADGE: '~aid-signature-badge',
  SIGNATURE_ADDITIONAL_TEXT_BADGE: '~aid-signature-additional-text',
  ATTACHMENT_TEXT_VIEW: '~aid-attachment-text-view',
  PUBLIC_KEY_LABEL: '~aid-public-key-label',
  FINGEPRINT_LABEL_VALUE: '~aid-fingerprint-value',
  PUBLIC_KEY_IMPORT_WARNING: '~aid-warning-label',
  TOGGLE_PUBLIC_KEY_NODE: '~aid-toggle-public-key-node',
  PUBLIC_KEY_VALUE: '~aid-public-key-value',
  IMPORT_PUBLIC_KEY_BUTTON: '~aid-import-key-button',
};

class EmailScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BTN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BTN);
  }

  get enterPassPhraseField() {
    return $(SELECTORS.ENTER_PASS_PHRASE_FIELD);
  }

  get okButton() {
    return $(SELECTORS.OK_BUTTON);
  }

  get enterPassPhraseTitleLabel() {
    return $(SELECTORS.ENTR_PASSPHRASE_TITLE_LABEL);
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

  get antiBruteForceIntroduceLabel() {
    return $(SELECTORS.ANTI_BRUTE_FORCE_INTRODUCE_LABEL);
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

  get helpButton() {
    return $(SELECTORS.HELP_BUTTON);
  }

  get archiveButton() {
    return $(SELECTORS.ARCHIVE_BUTTON);
  }

  get moveToInboxButton() {
    return $(SELECTORS.MOVE_TO_INBOX_BUTTON);
  }

  get deleteButton() {
    return $(SELECTORS.DELETE_BUTTON);
  }

  get unreadButton() {
    return $(SELECTORS.UNREAD_BUTTON);
  }

  get confirmDeletingButton() {
    return $(SELECTORS.CONFIRM_DELETING);
  }

  get downloadButton() {
    return $(SELECTORS.DOWNLOAD_BUTTON);
  }

  get encryptionBadge() {
    return $(SELECTORS.ENCRYPTION_BADGE);
  }

  get signatureBadge() {
    return $(SELECTORS.SIGNATURE_BADGE);
  }

  get additionalSignatureTextBadge() {
    return $(SELECTORS.SIGNATURE_ADDITIONAL_TEXT_BADGE);
  }

  get publicKeyLabel() {
    return $(SELECTORS.PUBLIC_KEY_LABEL);
  }

  get fingerprintLabelValue() {
    return $(SELECTORS.FINGEPRINT_LABEL_VALUE);
  }

  get publicKeyImportWarningLabel() {
    return $(SELECTORS.PUBLIC_KEY_IMPORT_WARNING);
  }

  get publicKeyToggle() {
    return $(SELECTORS.TOGGLE_PUBLIC_KEY_NODE);
  }

  get publicKeyValueLabel() {
    return $(SELECTORS.PUBLIC_KEY_VALUE);
  }

  get importPublicKeyButton() {
    return $(SELECTORS.IMPORT_PUBLIC_KEY_BUTTON);
  }

  get attachmentTextView() {
    return $(SELECTORS.ATTACHMENT_TEXT_VIEW);
  }

  checkEmailSender = async (sender: string, index = 0) => {
    const element = await this.senderEmail(index);
    await ElementHelper.waitElementVisible(element);
    expect(await element.getValue()).toEqual(sender);
  };

  senderEmail = async (index = 0) => {
    return $(`~aid-sender-${index}`);
  };

  checkEmailSubject = async (subject: string) => {
    const subjectElement = await $(`~${subject}`);
    await ElementHelper.waitElementVisible(subjectElement);
  };

  checkEmailText = async (text: string, index = 0, isHtml = false) => {
    let messageElValue;
    if (isHtml) {
      messageElValue = await WebView.getDocumentContent();
    } else {
      const messageEl = await $(`~aid-message-${index}`);
      await ElementHelper.waitElementVisible(messageEl);
      messageElValue = await messageEl.getValue();
    }
    if (text.length > 0) {
      expect(messageElValue).toContain(text);
    } else {
      expect(messageElValue).toBeNull();
    }
  };

  checkOpenedEmail = async (email: string, subject: string, text: string, isHtml = false) => {
    await this.checkEmailSender(email);
    await this.checkEmailSubject(subject);
    await this.checkEmailText(text, 0, isHtml);
  };

  checkThreadMessage = async (email: string, subject: string, text: string, index = 0, date?: string) => {
    await this.checkEmailSubject(subject);
    await this.checkEmailSender(email, index);
    await this.clickExpandButtonByIndex(index);
    await this.checkEmailText(text, index);
    if (date) {
      await this.checkDate(date, index);
    }
  };

  clickExpandButtonByIndex = async (index: number) => {
    const element = await $(`~aid-expand-image-${index}`);
    if (await element.isDisplayed()) {
      await ElementHelper.waitAndClick(element);
    }
  };

  messageQuote = async (index: number) => {
    return $(`~aid-message-${index}-quote`);
  };

  clickToggleQuoteButton = async (index: number) => {
    const element = await $(`~aid-message-${index}-quote-toggle`);
    if (await element.isDisplayed()) {
      try {
        await ElementHelper.waitAndClick(element);
      } catch {
        // Try to click quote toggle button one more time if quote doesn't appear
        await browser.pause(100);
        const quoteEl = await this.messageQuote(index);
        if (!(await quoteEl.isDisplayed())) {
          await ElementHelper.waitAndClick(element);
        }
      }
    }
  };

  checkQuoteIsHidden = async (index: number) => {
    await ElementHelper.waitElementInvisible(await this.messageQuote(index));
  };

  checkQuote = async (index: number, quote: string) => {
    const quoteElement = await this.messageQuote(index);
    await ElementHelper.waitElementVisible(quoteElement);
    const quoteElementValue = await quoteElement.getValue();
    expect(quoteElementValue).toContain(quote);
  };

  checkDate = async (date: string, index: number) => {
    const element = await $(`~aid-date-${index}`);
    await ElementHelper.waitElementVisible(element);
    expect(await element.getValue()).toEqual(date);
  };

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  };

  clickOkButton = async () => {
    await ElementHelper.waitAndClick(await this.okButton);
  };

  clickDownloadButton = async () => {
    await ElementHelper.waitAndClick(await this.downloadButton);
  };

  enterPassPhrase = async (text: string = CommonData.account.passPhrase) => {
    await ElementHelper.waitElementVisible(await this.enterPassPhraseField);
    await (await this.enterPassPhraseField).setValue(text);
  };

  checkAntiBruteForceIntroduceLabel = async (expectedValue: string) => {
    await ElementHelper.waitElementVisible(await this.antiBruteForceIntroduceLabel);
    const introduceLabel = await (await this.antiBruteForceIntroduceLabel).getValue();
    expect(introduceLabel.includes(expectedValue)).toEqual(true);
  };

  checkPassPhraseModalTitle = async (value = 'Wrong pass phrase, please try again') => {
    await ElementHelper.waitForText(await this.enterPassPhraseTitleLabel, value);
  };

  checkAttachment = async (name: string) => {
    await ElementHelper.waitForText(await this.attachmentTitle, name);
  };

  clickOnAttachmentCell = async () => {
    await ElementHelper.waitAndClick(await this.attachmentCell);
  };

  clickReplyButton = async () => {
    await ElementHelper.waitAndClick(await this.replyButton);
  };

  clickRecipientsButton = async () => {
    await ElementHelper.waitAndClick(await this.recipientsButton);
  };

  clickMenuButton = async () => {
    await ElementHelper.clickUntilExpectedElementAppears(await this.menuButton, await this.forwardButton);
  };

  clickForwardButton = async () => {
    await ElementHelper.waitAndClick(await this.forwardButton);
  };

  clickReplyAllButton = async () => {
    await ElementHelper.waitAndClick(await this.replyAllButton);
  };

  clickArchiveButton = async () => {
    await ElementHelper.waitAndClick(await this.archiveButton);
  };

  clickMoveToInboxButton = async () => {
    await ElementHelper.waitAndClick(await this.moveToInboxButton);
  };

  clickDeleteButton = async () => {
    await ElementHelper.waitAndClick(await this.deleteButton);
  };

  confirmDelete = async () => {
    await ElementHelper.waitAndClick(await this.confirmDeletingButton);
  };

  checkInboxEmailActions = async () => {
    await ElementHelper.waitElementVisible(await this.helpButton);
    await ElementHelper.waitElementVisible(await this.archiveButton);
    await ElementHelper.waitElementVisible(await this.deleteButton);
    await ElementHelper.waitElementVisible(await this.unreadButton);
  };

  checkArchivedEmailActions = async () => {
    await ElementHelper.waitElementVisible(await this.helpButton);
    await ElementHelper.waitElementVisible(await this.moveToInboxButton);
    await ElementHelper.waitElementVisible(await this.deleteButton);
    await ElementHelper.waitElementVisible(await this.unreadButton);
  };

  checkRecipientsButton = async (value: string) => {
    await ElementHelper.checkStaticText(await this.recipientsButton, value);
  };

  checkRecipientsList = async (to: string, cc: string, bcc: string) => {
    await ElementHelper.waitForText(await this.recipientsToLabel, to);
    await ElementHelper.waitForText(await this.recipientsCcLabel, cc);
    await ElementHelper.waitForText(await this.recipientsBccLabel, bcc);
  };

  checkEncryptionBadge = async (value: string) => {
    await ElementHelper.checkStaticText(await this.encryptionBadge, value);
  };

  checkSignatureBadge = async (value: string, additionalText?: string) => {
    const signatureBadge = await this.signatureBadge;
    await ElementHelper.checkStaticText(await this.signatureBadge, value);
    if (additionalText) {
      await ElementHelper.waitAndClick(signatureBadge);
      await ElementHelper.checkStaticText(await this.additionalSignatureTextBadge, additionalText);
    }
  };

  checkAttachmentTextView = async (value: string) => {
    const el = await this.attachmentTextView;
    await ElementHelper.waitElementVisible(el);
    const text = await el.getText();
    expect(text.includes(value)).toBeTruthy();
  };

  checkPublicKeyImportView = async (email: string, fingerprint: string, isAlreadyImported = false) => {
    await ElementHelper.waitForText(await this.publicKeyLabel, email, 3000, true);
    await ElementHelper.waitForText(await this.fingerprintLabelValue, fingerprint, 3000, true);
    await ElementHelper.waitElementVisible(await this.importPublicKeyButton);
    if (!isAlreadyImported) {
      await ElementHelper.waitElementVisible(await this.publicKeyImportWarningLabel);
    }
    // Check if public key toggle works correctly (should show/hide public key value label)
    await ElementHelper.waitAndClick(await this.publicKeyToggle);
    await ElementHelper.waitElementVisible(await this.publicKeyValueLabel);
    await ElementHelper.waitAndClick(await this.publicKeyToggle);
    await ElementHelper.waitElementInvisible(await this.publicKeyValueLabel);
  };

  importPublicKey = async () => {
    await ElementHelper.waitAndClick(await this.importPublicKeyButton);
    await ElementHelper.waitForText(await this.importPublicKeyButton, 'Already imported');
    await ElementHelper.waitElementInvisible(await this.publicKeyImportWarningLabel);
  };

  draftBody = async (index: number) => {
    return $(`~aid-draft-body-${index}`);
  };

  checkDraft = async (text: string, index: number) => {
    await ElementHelper.waitForText(await this.draftBody(index), text);
  };

  openDraft = async (index: number) => {
    await ElementHelper.waitAndClick(await this.draftBody(index));
  };

  deleteDraft = async (index: number) => {
    await ElementHelper.waitAndClick(await $(`~aid-draft-delete-button-${index}`));
    await this.confirmDelete();
    await ElementHelper.waitElementInvisible(await this.draftBody(index));
  };
}

export default new EmailScreen();
