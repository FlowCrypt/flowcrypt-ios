import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import TouchHelper from 'tests/helpers/TouchHelper';
import moment from 'moment'

const SELECTORS = {
  BACK_BTN: '~aid-back-button',
  SHARE_BUTTON: '~share',
  COPY_BUTTON: '~copy',
  KEY_LABEL: '~Key',
  PUBLIC_KEY_VALUE: '~aid-signature-key',
  TRASH_BUTTON: '~trash',
  SIGNATURE_LABEL: '~Signature',
  SIGNATURE_VALUE: '~aid-signature-date',
  LAST_FETCHED_DATE_LABEL: '~Last fetched',
  LAST_FETCHED_DATE_VALUE: '~aid-signature-fetched-date',
  FINGERPRINTS_VALUE: '~aid-signature-fingerprints',
  FINGERPRINTS_LABEL: '~Fingerprints'
};

class PublicKeyDetailsScreen extends BaseScreen {
  constructor() {
      super(SELECTORS.BACK_BTN);
  }

  get trashButton() {
      return $(SELECTORS.TRASH_BUTTON);
  }

  get copyButton() {
      return $(SELECTORS.COPY_BUTTON);
  }

  get shareButton() {
      return $(SELECTORS.SHARE_BUTTON)
  }

  get backButton() {
      return $(SELECTORS.BACK_BTN);
  }

  get keyLabel() {
      return $(SELECTORS.KEY_LABEL);
  }

  get signatureLabel() {
      return $(SELECTORS.SIGNATURE_LABEL)
  }

  get signatureValue() {
      return $(SELECTORS.SIGNATURE_VALUE);
  }

  get publicKeyValue() {
      return $(SELECTORS.PUBLIC_KEY_VALUE);
  }

  get lastFetchedDateLabel() {
      return $(SELECTORS.LAST_FETCHED_DATE_LABEL)
  }

  get lastFetchedDateValue() {
      return $(SELECTORS.LAST_FETCHED_DATE_VALUE)
  }

  get fingerprintsLabel() {
      return $(SELECTORS.FINGERPRINTS_LABEL);
  }

  get fingerprintsValue() {
      return $(SELECTORS.FINGERPRINTS_VALUE)
  }

  checkPublicKeyDetailsScreen = async () => {
    await (await this.trashButton).waitForDisplayed();
    await (await this.copyButton).waitForDisplayed();
    await (await this.shareButton).waitForDisplayed();
    await (await this.keyLabel).waitForDisplayed();
    await TouchHelper.scrollDown();
    await (await this.signatureLabel).waitForDisplayed();
    await (await this.lastFetchedDateLabel).waitForDisplayed();
    await (await this.fingerprintsLabel).waitForDisplayed();
  }

  checkPublicKeyNotEmpty = async () => {
    const pubkeyEl = await this.publicKeyValue;
    await pubkeyEl.waitForExist();
    expect(await pubkeyEl.getAttribute('value')).toBeTruthy();
  }

  checkSignatureDateValue = async (value: string) => {
    const signatureValue = await this.signatureValue.getValue();
    const convertedToUTC = moment(signatureValue.replace('at', '')).utcOffset(0).format('D MMM yyyy, hh:mm:ss A');
    expect(convertedToUTC).toEqual(value);
  }

  getLastFetchedDateValue = async () => {
    await (await this.lastFetchedDateLabel).waitForDisplayed();
    const lastFetchedDate = await this.lastFetchedDateValue;
    return (await lastFetchedDate.getAttribute('value'));
  }

  checkFingerPrintsValue = async (value: string) => {
    const fingerprints = await this.fingerprintsValue;
    await fingerprints.waitForExist();
    expect(await fingerprints.getAttribute('value')).toEqual(value);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  clickTrashButton = async () => {
    await ElementHelper.waitAndClick(await this.trashButton);
  }
}

export default new PublicKeyDetailsScreen();
