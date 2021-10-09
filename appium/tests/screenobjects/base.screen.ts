import { DEFAULT_TIMEOUT } from '../constants';

export default class BaseScreen {

    locator: string;
    constructor (selector: string) {
        this.locator = selector;
    }

    /**
     * Wait for screen to be visible
     *
     * @param {boolean} isShown
     * @return {boolean}
     */
    waitForScreen (isShown: boolean = true) {
        return $(this.locator).waitForDisplayed({
            timeout: DEFAULT_TIMEOUT,
            reverse: !isShown,
        });
    }
}
