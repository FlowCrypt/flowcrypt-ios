type ScreenPosition = 'topLeft' | 'topCenter' | 'topRight' | 'centerLeft' | 'centerCenter' | 'centerRight' | 'bottomLeft' | 'bottomCenter' | 'bottomRight';

class TouchHelper {

  /**
  * scroll down
  */
  static scrollDown = async () => {
    await driver.execute('mobile: scroll', { direction: 'down' });
  }

  /**
  * scroll up
  */
  static scrollUp = async () => {
    await driver.execute('mobile: scroll', { direction: 'up' });
  }

  /**
   * Tap Screen
   */
  static tapScreen = async (position: ScreenPosition) => {
    const { width, height } = await driver.getWindowSize();
    let pressOptions;
    switch (position) {
      case 'topLeft':
        pressOptions = { x: 0, y: 0 };
        break;
      case 'topCenter':
        pressOptions = { x: width / 2, y: 0 };
        break;
      case 'topRight':
        pressOptions = { x: width, y: 0 };
        break;
      case 'centerLeft':
        pressOptions = { x: 0, y: height / 2 };
        break;
      case 'centerCenter':
        pressOptions = { x: width / 2, y: height / 2 };
        break;
      case 'centerRight':
        pressOptions = { x: width, y: height / 2 };
        break;
      case 'bottomLeft':
        pressOptions = { x: 0, y: height };
        break;
      case 'bottomCenter':
        pressOptions = { x: width / 2, y: height };
        break;
      case 'bottomRight':
        pressOptions = { x: width, y: height };
        break;
    }
    await driver.touchPerform([
      { action: 'press', options: pressOptions },
      { action: 'wait', options: { ms: 100 } },
      { action: 'release', options: {} },
    ]);
    await browser.pause(100);
  }

  static pullToRefresh = async () => {
    const { width, height } = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.3;
    const endPoint = height * 0.8;
    await browser.pause(1000); // due to scroll action which takes about second
    await driver.touchPerform([
      { action: 'press', options: { x: anchor, y: startPoint } },
      { action: 'wait', options: { ms: 100 } },
      { action: 'moveTo', options: { x: anchor, y: endPoint } },
      { action: 'wait', options: { ms: 1000 } },
      { action: 'release', options: {} },
    ]);
  }

  static scrollDownToElement = async (element: WebdriverIO.Element) => {
    const { width, height } = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.65;
    const endPoint = height * 0.1;

    // this wait can be later replaced by waiting for loader to go away before scrolling
    await browser.pause(1000); // make sure contents are loaded first, so we don't scroll too early
    for (let i = 0; i < 15; i++) {
      if (await element.isDisplayed()) {
        return;
      }
      await driver.touchPerform([
        { action: 'press', options: { x: anchor, y: startPoint } },
        { action: 'wait', options: { ms: 100 } },
        { action: 'moveTo', options: { x: anchor, y: endPoint } },
        { action: 'release', options: {} },
      ]);
      await browser.pause(1000); // due to scroll action which takes about second
    }
    throw new Error(`Element ${JSON.stringify(element.selector)} not displayed after scroll`);
  }

  static scrollUpToElement = async (element: WebdriverIO.Element) => {
    const { width, height } = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.15;
    const endPoint = height * 0.75;

    // this wait can be later replaced by waiting for loader to go away before scrolling
    await browser.pause(1000); // make sure contents are loaded first, so we don't scroll too early
    for (let i = 0; i < 15; i++) {
      if (await element.isDisplayed()) {
        return;
      }
      await driver.touchPerform([
        { action: 'press', options: { x: anchor, y: startPoint } },
        { action: 'wait', options: { ms: 100 } },
        { action: 'moveTo', options: { x: anchor, y: endPoint } },
        { action: 'release', options: {} },
      ]);
      await browser.pause(1000); // due to scroll action which takes about second
    }
    throw new Error(`Element ${JSON.stringify(element.selector)} not displayed after scroll`);
  }
}
export default TouchHelper;
