import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";

const SELECTORS = {
  SENT_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "SENT"`]',
  SEARCH_ICON: '~search icn',
  HELP_ICON: '~help icn'
};


class SentScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SEARCH_ICON);
  }

  get searchIcon() {
    return $(SELECTORS.SEARCH_ICON);
  }

  get helpIcon() {
    return $(SELECTORS.HELP_ICON);
  }

  get sentHeader() {
    return $(SELECTORS.SENT_HEADER)
  }

  checkSentScreen = async () => {
    await expect(await this.sentHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  checkEmailIsNotDisplayed = async (subject: string) => {
    await (await $(`~${subject}`)).waitForDisplayed({reverse: true});
  }

  refreshSentList = async () => {
    await TouchHelper.scrollUp();
  }
}

export default new SentScreen();
