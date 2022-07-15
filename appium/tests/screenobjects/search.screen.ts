import BaseScreen from './base.screen';
import ElementHelper from "../helpers/ElementHelper";
import TouchHelper from 'tests/helpers/TouchHelper';

const SELECTORS = {
  BACK_BUTTON: '~aid-back-button',
  SCREEN: '~aid-search-view-controller',
  SEARCH_FIELD: '~aid-search-all-emails-field'
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
    // Stability to wait for search caret to be displayed
    await browser.pause(1000);
    await ElementHelper.waitAndPasteString(await this.searchField, `subject: '${subject}'`);

    const subjectEl = await $(`~${subject}`);
    if (!await subjectEl.isDisplayed()) {
      await TouchHelper.scrollDownToElement(subjectEl);
    }
    await ElementHelper.waitAndClick(subjectEl, 500);
  }

  searchAndClickEmailForOutlook = async (subject: string) => {
    await (await this.searchField).setValue(subject);

    const selector = `~${subject}`;
    await ElementHelper.waitAndClick(await $(selector), 500);
  }
}

export default new SearchScreen();
