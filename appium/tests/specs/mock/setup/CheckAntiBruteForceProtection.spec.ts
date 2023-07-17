import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { CommonData } from 'tests/data';

describe('INBOX: ', () => {
  it('check anti brute force protection', async () => {
    const mockApi = new MockApi();
    const subject = 'Signed and encrypted message';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    const processArgs = CommonData.mockProcessArgs;
    const wrongPassPhrase = 'test1234';

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await AppiumHelper.restartApp(processArgs);
      await MailFolderScreen.clickOnEmailBySubject(subject);

      for (const i of [4, 3, 2, 1, 0]) {
        await EmailScreen.enterPassPhrase(wrongPassPhrase);
        await EmailScreen.clickOkButton();
        if (i > 0) {
          await EmailScreen.checkAntiBruteForceIntroduceLabel(
            `For your protection and data security, there are currently only ${i} attempt${i > 1 ? 's' : ''}`,
          );
        }
      }
      await EmailScreen.checkAntiBruteForceIntroduceLabel(
        'To protect you and your data, the next attempt will only be possible after the timer below finishes. Please wait until then before trying again.',
      );
      expect(await (await EmailScreen.okButton).isEnabled()).toEqual(false);
    });
  });
});
