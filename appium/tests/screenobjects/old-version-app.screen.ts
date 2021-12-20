import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BUTTON: '~arrow left c',
  SENDER_EMAIL: '~messageSenderLabel',
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

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
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
    await this.checkEmailAddress(email);
    await this.checkEmailSubject(subject);
    await this.checkEmailText(text);
  }
}

export default new OldVersionAppScreen();
