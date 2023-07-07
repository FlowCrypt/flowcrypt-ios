import { CommonData } from '../data';

class AppiumHelper {
  /**
   * Restart app with processArguments
   */
  static async restartApp(processArgs: string[] = []) {
    const bundleId = CommonData.bundleId.id;
    await driver.terminateApp(bundleId);
    const args = {
      bundleId,
      arguments: processArgs,
    };
    await driver.execute('mobile: launchApp', args);
  }
}

export default AppiumHelper;
