import BaseScreen from './base.screen';
import TouchHelper from "../helpers/TouchHelper";

const SELECTORS = {
  TRASH_HEADER: '-ios class chain:**/XCUIElementTypeNavigationBar[`name == "TRASH"`]',
  SEARCH_ICON: '~search icn',
  HELP_ICON: '~help icn'
};

class TrashScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SEARCH_ICON);
  }

  get searchIcon() {
    return $(SELECTORS.SEARCH_ICON);
  }

  get helpIcon() {
    return $(SELECTORS.HELP_ICON);
  }

  get trashHeader() {
    return $(SELECTORS.TRASH_HEADER)
  }

  checkTrashScreen = async () => {
    await expect(await this.trashHeader).toBeDisplayed();
    await expect(await this.searchIcon).toBeDisplayed();
    await expect(await this.helpIcon).toBeDisplayed()
  }

  checkEmailIsNotDisplayed = async (subject: string) => {
    await (await $(`~${subject}`)).waitForDisplayed({ reverse: true });
  }

  refreshTrashList = async () => {
    await TouchHelper.scrollUp();
  }
}

export default new TrashScreen();
