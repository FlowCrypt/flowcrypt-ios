import { DEFAULT_TIMEOUT } from '../constants';

class ElementHelper {
  /**
   * returns true or false for element visibility
   */
  static elementDisplayed = async (element: WebdriverIO.Element): Promise<boolean> => {
    return await element.isDisplayed();
  };

  static waitElementVisible = async (element: WebdriverIO.Element, timeout: number = DEFAULT_TIMEOUT) => {
    try {
      await element.waitForDisplayed({ timeout: timeout });
    } catch (error) {
      throw new Error(`Element isn't visible after ${timeout} seconds. Error: ${error}`);
    }
  };

  static waitElementInvisible = async (element: WebdriverIO.Element, timeout: number = DEFAULT_TIMEOUT) => {
    try {
      await element.waitForDisplayed({ timeout: timeout, reverse: true });
    } catch (error) {
      throw new Error(`Element still visible after ${timeout} seconds. Error: ${error}`);
    }
  };

  static staticText = async (label: string) => {
    const selector = `**/XCUIElementTypeStaticText[\`label == "${label}"\`]`;
    return await $(`-ios class chain:${selector}`);
  };

  static staticTextContains = async (label: string) => {
    const selector = `**/XCUIElementTypeStaticText[\`label CONTAINS "${label}"\`]`;
    return await $(`-ios class chain:${selector}`);
  };

  static clickStaticText = async (label: string) => {
    await ElementHelper.waitAndClick(await this.staticText(label));
  };

  static checkStaticText = async (element: WebdriverIO.Element, label: string) => {
    await this.waitElementVisible(element);
    await this.waitForText(element, label);
  };

  static doubleClick = async (element: WebdriverIO.Element) => {
    await this.waitElementVisible(element);
    await element.doubleClick();
  };

  static waitAndClick = async (element: WebdriverIO.Element, delayMs = 50) => {
    await this.waitElementVisible(element);
    // stability fix to make sure element is ready for interaction
    await browser.pause(delayMs);
    await element.click();
  };

  static clickUntilExpectedElementAppears = async (
    element: WebdriverIO.Element,
    expectedElement: WebdriverIO.Element,
    maximumRetries = 3,
  ) => {
    await this.waitElementVisible(element);
    let currentRetryCount = 0;
    let isExpectedElementVisible = await expectedElement.isDisplayed();
    while (!isExpectedElementVisible && currentRetryCount < maximumRetries) {
      if (await element.isDisplayed()) {
        await element.click();
      }
      await browser.pause(3000);
      isExpectedElementVisible = await expectedElement.isDisplayed();
      if (isExpectedElementVisible) {
        return;
      }
      currentRetryCount += 1;
    }
    if (currentRetryCount >= maximumRetries) {
      throw new Error(`The expected web element didn't appear after ${maximumRetries} attempts.`);
    }
  };

  static clearInput = async (element: WebdriverIO.Element) => {
    const elValue = await element.getValue();
    if (!elValue) {
      return;
    }

    await this.waitAndClick(element);
    await browser.pause(200);
    const selectAllButton = await $('~Select All');
    // Check if 'Select All' is not displayed, if so, click the element again.
    if (!(await selectAllButton.isDisplayed())) {
      await this.waitAndClick(element);
    }

    await this.waitAndClick(selectAllButton);

    await driver.sendKeys(['\b']); // backspace
  };

  static async copyStringIntoClipboard(text: string) {
    const base64Encoded = Buffer.from(text).toString('base64');
    await driver.setClipboard(base64Encoded);
  }

  static async waitAndPasteString(element: WebdriverIO.Element, text: string) {
    await ElementHelper.copyStringIntoClipboard(text);
    await browser.pause(100);
    await ElementHelper.waitAndClick(element);
    const pasteEl = await $('~Paste');
    await ElementHelper.waitAndClick(pasteEl);
  }

  static waitClickAndType = async (element: WebdriverIO.Element, text: string) => {
    await this.waitAndClick(element);
    await element.setValue(text);
  };

  //wait for text in element during 15 seconds (if the text doesn't appear during 15s, it will show the error)
  static waitForText = async (
    element: WebdriverIO.Element,
    text: string,
    timeout: number = DEFAULT_TIMEOUT,
    checkContains = false,
  ) => {
    await this.waitElementVisible(element);
    await element.waitUntil(
      async function () {
        const elementText = await element.getText();
        if (checkContains) {
          return elementText.includes(text);
        }
        return elementText === text;
      },
      {
        timeout: timeout,
        timeoutMsg: `expected text within ${timeout}ms to be "${text}" but got last value "${await element.getText()}"`,
      },
    );
  };

  //wait for value in element during 15 seconds (if the value doesn't appear during 15s, it will show the error)
  static waitForValue = async (
    element: WebdriverIO.Element,
    value: string,
    timeout: number = DEFAULT_TIMEOUT,
    checkContains = false,
  ) => {
    await this.waitElementVisible(element);
    await element.waitUntil(
      async function () {
        const elementValue = await element.getValue();
        if (checkContains) {
          return elementValue.includes(value);
        }
        return elementValue === value;
      },
      {
        timeout: timeout,
        timeoutMsg: `expected text within ${timeout}ms to be "${value}" but got last value "${await element.getValue()}"`,
      },
    );
  };
}

export default ElementHelper;
