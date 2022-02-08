

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

  static pullToRefresh = async () =>{
    const {width, height} = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.3;
    const endPoint = height * 0.8;
    await browser.pause(1000); // due to scroll action which takes about second
    await driver.touchPerform([
      {action: 'press', options: {x: anchor, y: startPoint}},
      {action: 'wait', options: {ms: 100}},
      {action: 'moveTo', options: {x: anchor, y: endPoint}},
      {action: 'wait', options: {ms: 1000}},
      {action: 'release', options: {}},
    ]);
  }

  static scrollDownToElement = async (element: WebdriverIO.Element) => {
    const { width, height } = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.75;
    const endPoint = height * 0.15;

    // this wait can be later replaced by waiting for loader to go away before scrolling
    await browser.pause(1000); // make sure contents are loaded first, so we don't scroll too early
    for(let i = 0; i < 15; i++) {
      if (await element.isDisplayed()) {
        return;
      }
      await driver.touchPerform([
        {action: 'press', options: {x: anchor, y: startPoint}},
        {action: 'wait', options: {ms: 100}},
        {action: 'moveTo', options: {x: anchor, y: endPoint}},
        {action: 'release', options: {}},
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
    for(let i = 0; i < 15; i++) {
      if (await element.isDisplayed()) {
       return;
      }
      await driver.touchPerform([
        {action: 'press', options: {x: anchor, y: startPoint}},
        {action: 'wait', options: {ms: 100}},
        {action: 'moveTo', options: {x: anchor, y: endPoint}},
        {action: 'release', options: {}},
      ]);
      await browser.pause(1000); // due to scroll action which takes about second
    }
    throw new Error(`Element ${JSON.stringify(element.selector)} not displayed after scroll`);
  }
}
export default TouchHelper;
