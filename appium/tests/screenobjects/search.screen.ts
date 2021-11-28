import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";

const SELECTORS = {
  BACK_BUTTON: '~arrow left c',
  SCREEN: '~searchViewController',
  SEARCH_FIELD: '~searchField'  
};

class SearchScreen extends BaseScreen {
  constructor() {
    super(SELECTORS.SCREEN);
  }

  get screen() {
    return $(SELECTORS.SCREEN)
  }  

  get backButton() {
    return $(SELECTORS.BACK_BUTTON)
  }

  get searchField() {
    return $(SELECTORS.SEARCH_FIELD);
  }

  checkScreen = async () => {
    await browser.pause(2000);
    await (await this.screen).waitForDisplayed();
  }

  clickBackButton = async () => {
    await ElementHelper.waitAndClick(await this.backButton);
  }

  searchAndClickEmailBySubject = async (subject: string) => {
    await (await this.searchField).setValue(`subject: '${subject}'`);

    const selector = `~${subject}`;
    await ElementHelper.waitAndClick(await $(selector), 500);
  }
}

export default new SearchScreen();
