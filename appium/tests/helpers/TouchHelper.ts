
class TouchHelper {

  /**
  * scroll down
  */
  static scrollDown = async() => {
    await driver.execute('mobile: scroll', {direction: 'down'});
  }

  /**
  * scroll up
  */
  static scrollUp = async() => {
    await driver.execute('mobile: scroll', {direction: 'up'});
  }

}

export default TouchHelper;
