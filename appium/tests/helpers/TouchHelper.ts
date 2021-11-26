
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
}

export default TouchHelper;
