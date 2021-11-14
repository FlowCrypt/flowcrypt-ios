import { DEFAULT_TIMEOUT } from "../constants";

class ElementHelper {

  /**
   * returns true or false for element visibility
   */
  static elementDisplayed = async (element: WebdriverIO.Element): Promise<boolean> => {
    return await element.isExisting();
  }

  static waitElementVisible = async (element: WebdriverIO.Element, timeout: number = DEFAULT_TIMEOUT) => {
    try {
      await element.waitForDisplayed({ timeout: timeout });
    } catch (error) {
      throw new Error(`Element isn't visible after ${timeout} seconds. Error: ${error}`);
    }
  }

  static waitElementInvisible = async (element: WebdriverIO.Element, timeout: number = DEFAULT_TIMEOUT) => {
    try {
      await element.waitForDisplayed({ timeout: timeout, reverse: true });
    } catch (error) {
      throw new Error(`Element still visible after ${timeout} seconds. Error: ${error}`);
    }
  }

  static staticText = async (label: string) => {
    const selector = `**/XCUIElementTypeStaticText[\`label == "${label}"\`]`;
    return await $(`-ios class chain:${selector}`);
  }

  static staticTextContains = async (label: string) => {
    const selector = `**/XCUIElementTypeStaticText[\`label CONTAINS "${label}"\`]`;
    return await $(`-ios class chain:${selector}`);
  }

  static clickStaticText = async (label: string) => {
    await this.waitElementVisible(await this.staticText(label));
    const element = await this.staticText(label);
    await element.click();
  }

  static doubleClick = async (element: WebdriverIO.Element) => {
    await this.waitElementVisible(element);
    await element.doubleClick();
  }

  static waitAndClick = async (element: WebdriverIO.Element, delayMs = 10) => {
    await element.waitForDisplayed();
    // stability fix to make sure element is ready for interaction
    await browser.pause(delayMs)
    await element.click();
  }

  static waitClickAndType = async (element: WebdriverIO.Element, text: string) => {
    await this.waitAndClick(element)
    await element.setValue(text);
  }
}

export default ElementHelper;
