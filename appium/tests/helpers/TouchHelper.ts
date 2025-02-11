type ScreenPosition =
  | 'topLeft'
  | 'topCenter'
  | 'topRight'
  | 'centerLeft'
  | 'centerCenter'
  | 'centerRight'
  | 'bottomLeft'
  | 'bottomCenter'
  | 'bottomRight';

class TouchHelper {
  /**
   * scroll down
   */
  static scrollDown = async () => {
    await driver.execute('mobile: scroll', { direction: 'down' });
  };

  /**
   * scroll up
   */
  static scrollUp = async () => {
    await driver.execute('mobile: scroll', { direction: 'up' });
  };

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
    await TouchHelper.tapScreenAt(pressOptions);
  };

  static tapScreenAt = async ({ x, y }: { x: number; y: number }) => {
    await driver.execute('mobile: tap', { x, y });
    await browser.pause(100);
  };

  static pullToRefresh = async () => {
    const { width, height } = await driver.getWindowSize();
    const anchor = width / 2;
    const startPoint = height * 0.3;
    const endPoint = height * 0.8;
    await browser.pause(1000); // due to scroll action which takes about second

    await driver.performActions([
      {
        id: 'pullToRefresh',
        type: 'pointer',
        parameters: { pointerType: 'touch' },
        actions: [
          { duration: 0, x: anchor, y: startPoint, type: 'pointerMove', origin: 'viewport' },
          { button: 0, type: 'pointerDown' },
          { type: 'pause', duration: 100 },
          { duration: 0, x: anchor, y: endPoint, type: 'pointerMove', origin: 'viewport' },
          { type: 'pause', duration: 1000 },
          { button: 0, type: 'pointerUp' },
        ],
      },
    ]);
  };

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
      await driver.performActions([
        {
          id: 'scrollDownToElement',
          type: 'pointer',
          parameters: { pointerType: 'touch' },
          actions: [
            { duration: 0, x: anchor, y: startPoint, type: 'pointerMove', origin: 'viewport' },
            { button: 0, type: 'pointerDown' },
            { type: 'pause', duration: 100 },
            { duration: 0, x: anchor, y: endPoint, type: 'pointerMove', origin: 'viewport' },
            { button: 0, type: 'pointerUp' },
          ],
        },
      ]);
      await browser.pause(1000); // due to scroll action which takes about second
    }
    throw new Error(`Element ${JSON.stringify(element.selector)} not displayed after scroll`);
  };

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
      await driver.performActions([
        {
          id: 'scrollUpToElement',
          type: 'pointer',
          parameters: { pointerType: 'touch' },
          actions: [
            { duration: 0, x: anchor, y: startPoint, type: 'pointerMove', origin: 'viewport' },
            { button: 0, type: 'pointerDown' },
            { type: 'pause', duration: 100 },
            { duration: 0, x: anchor, y: endPoint, type: 'pointerMove', origin: 'viewport' },
            { button: 0, type: 'pointerUp' },
          ],
        },
      ]);
      await browser.pause(1000); // due to scroll action which takes about second
    }
    throw new Error(`Element ${JSON.stringify(element.selector)} not displayed after scroll`);
  };

  static swipeElement = async (element: WebdriverIO.Element, side: 'leading' | 'trailing') => {
    const location = await element.getLocation();
    const size = await element.getSize();

    const midX = location.x + size.width / 2;
    const midY = location.y + size.height / 2;

    const targetX = side === 'leading' ? midX + 100 : midX - 100;

    await driver.performActions([
      {
        id: 'swipeElement',
        type: 'pointer',
        parameters: { pointerType: 'touch' },
        actions: [
          {
            duration: 0,
            x: midX,
            y: midY,
            type: 'pointerMove',
            origin: 'viewport',
          },
          { button: 1, type: 'pointerDown' },
          { duration: 600, type: 'pause' },
          {
            duration: 600,
            x: targetX,
            y: midY,
            type: 'pointerMove',
            origin: 'viewport',
          },
          { button: 1, type: 'pointerUp' },
        ],
      },
    ]);
  };

  static tapSwipeAction = async (element: WebdriverIO.Element, side: 'leading' | 'trailing') => {
    const window = await driver.getWindowSize();
    const location = await element.getLocation();
    const size = await element.getSize();

    const x = side === 'leading' ? 0 : window.width - 50;
    const y = location.y + size.height / 2;

    await driver.performActions([
      {
        id: 'tapSwipeAction',
        type: 'pointer',
        parameters: { pointerType: 'touch' },
        actions: [
          { duration: 0, x, y, type: 'pointerMove', origin: 'viewport' },
          { button: 0, type: 'pointerDown' },
          { type: 'pause', duration: 100 },
          { button: 0, type: 'pointerUp' },
        ],
      },
    ]);
  };
}
export default TouchHelper;
