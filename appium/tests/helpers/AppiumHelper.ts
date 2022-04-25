import { CommonData } from "../data";

class AppiumHelper {
    /**
     * Restart app with processArguments
     */
    static async restartApp() {
        const bundleId = CommonData.bundleId.id;
        await driver.terminateApp(bundleId);
        const processArgs = ['--mock-fes-api', '--mock-attester-api'];
        const args = {
            bundleId,
            arguments: processArgs
        }
        await driver.execute('mobile: launchApp', args);
    }
}

export default AppiumHelper;
