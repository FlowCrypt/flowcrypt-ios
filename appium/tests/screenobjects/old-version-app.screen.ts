import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BUTTON: '~arrow left c',
  SENDER_EMAIL: '~messageSenderLabel',
  PUBLIC_KEY: '-ios class chain:**/XCUIElementTypeOther/XCUIElementTypeStaticText[2]'
};

class OldVersionAppScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.BACK_BUTTON);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON)
  }

  get senderEmail() {
    return $(SELECTORS.SENDER_EMAIL);
  }
  get publicKeyValue () {
      return $(SELECTORS.PUBLIC_KEY);
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton, 500);
  }

  checkEmailAddress = async (email: string) => {
    await ElementHelper.waitForText(await this.senderEmail, email);
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
    await this.checkEmailAddress(email);
    await this.checkEmailSubject(subject);
    await this.checkEmailText(text);
  }

  checkPublicKeyNotEmpty = async () => {
    const pubkeyEl = await this.publicKeyValue;
    await pubkeyEl.waitForExist();
    expect(await pubkeyEl.getAttribute('value')).toBeTruthy();
  }
}

export default new OldVersionAppScreen();
