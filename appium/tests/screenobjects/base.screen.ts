import { DEFAULT_TIMEOUT } from '../constants';

export default class BaseScreen {

  locator: string;
  constructor(selector: string) {
    this.locator = selector;
  }

  /**
   * Wait for screen to be visible
   *
   * @param {boolean} isShown
   * @return {boolean}
   */
  waitForScreen = async (isShown: boolean = true) => {
    return await (await $(this.locator)).waitForDisplayed({
      timeout: DEFAULT_TIMEOUT,
      reverse: !isShown,
    });
  }
}
