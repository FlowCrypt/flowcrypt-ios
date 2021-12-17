import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BUTTON: '~aid-back-button',
  SCREEN: '~searchViewController',
  SEARCH_FIELD: '~searchAllEmailField'
};

class SearchScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SCREEN);
  }

  get backButton() {
    return $(SELECTORS.BACK_BUTTON)
  }

  get searchField() {
    return $(SELECTORS.SEARCH_FIELD);
  }

  clickBackButton = async () => {
    await browser.pause(2000);
    await ElementHelper.waitAndClick(await this.backButton);
  }

  searchAndClickEmailBySubject = async (subject: string) => {
    await (await this.searchField).setValue(`subject: '${subject}'`);

    const selector = `~${subject}`;
    await ElementHelper.waitAndClick(await $(selector), 500);
  }
}

export default new SearchScreen();
