import {DEFAULT_TIMEOUT} from "../constants";

class ElementHelper {

    /**
     * returns true or false for element visibility
     */
    static elementDisplayed(element): boolean {
        return element.isExisting();
    }

    static waitElementVisible(element, timeout: number = DEFAULT_TIMEOUT) {
        try {
            element.waitForDisplayed({timeout: timeout});
        } catch (error) {
            throw new Error(`Element isn't visible after ${timeout} seconds. Error: ${error}`);
        }
    }

    static waitElementInvisible(element, timeout: number = DEFAULT_TIMEOUT) {
        try {
            element.waitForDisplayed({timeout: timeout, reverse: true});
        } catch (error) {
            throw new Error(`Element still visible after ${timeout} seconds. Error: ${error}`);
        }
    }

    static staticText(label: string) {
        const selector = `**/XCUIElementTypeStaticText[\`label == "${label}"\`]`;
        return $(`-ios class chain:${selector}`);
    }

    static staticTextContains(label: string) {
        const selector = `**/XCUIElementTypeStaticText[\`label CONTAINS "${label}"\`]`;
        return $(`-ios class chain:${selector}`);
    }

    static clickStaticText (label: string) {
        this.waitElementVisible(this.staticText(label));
        this.staticText(label).click();
    }

    static doubleClick(element) {
        this.waitElementVisible(element);
        element.doubleClick();
    }
}

export default ElementHelper;
