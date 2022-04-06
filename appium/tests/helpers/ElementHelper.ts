import { DEFAULT_TIMEOUT } from "../constants";

class ElementHelper {

  /**
   * returns true or false for element visibility
   */
  static elementDisplayed = async (element: WebdriverIO.Element): Promise<boolean> => {
    return await element.isDisplayed();
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
    await ElementHelper.waitAndClick(await this.staticText(label));
  }

  static checkStaticText = async (element: WebdriverIO.Element, label: string) => {
    await this.waitElementVisible(element);
    await expect(element).toHaveText(label);
  }

  static doubleClick = async (element: WebdriverIO.Element) => {
    await this.waitElementVisible(element);
    await element.doubleClick();
  }

  static waitAndClick = async (element: WebdriverIO.Element, delayMs = 50) => {
    await this.waitElementVisible(element);
    // stability fix to make sure element is ready for interaction
    await browser.pause(delayMs);
    await element.click();
  }

  static waitClickAndType = async (element: WebdriverIO.Element, text: string) => {
    await this.waitAndClick(element);
    await element.setValue(text);
  }

  static waitForText = async (element: WebdriverIO.Element, text: string, timeout: number = DEFAULT_TIMEOUT) => {
    await this.waitElementVisible(element);
    await element.waitUntil(async  function () {
      return (await element.getText() === text)
    }, {
      timeout: timeout,
      timeoutMsg: 'expected text to be different after 5s'
    });
  }

  static waitForValue = async (element: WebdriverIO.Element, value: string, timeout: number = DEFAULT_TIMEOUT) => {
    await this.waitElementVisible(element);
    await element.waitUntil(async  function () {
      return (await element.getValue() === value)
    }, {
      timeout: timeout,
      timeoutMsg: 'expected value to be different after 15s'
    });
  }

}

export default ElementHelper;
