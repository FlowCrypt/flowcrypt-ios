import { DEFAULT_TIMEOUT } from '../constants';

export default class BaseScreen {

    locator: string;
    constructor(selector: string) {
      this.locator = selector;
    }

    waitForScreen = async (isShown = true) => {
      await (await $(this.locator)).waitForDisplayed({
        timeout: DEFAULT_TIMEOUT,
        reverse: !isShown,
      });
    }
}
