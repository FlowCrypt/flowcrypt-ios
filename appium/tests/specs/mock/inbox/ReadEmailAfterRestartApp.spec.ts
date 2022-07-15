import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('INBOX: ', () => {

  it('user is able to see plain email without setting pass phrase after restart app', async () => {

    const processArgs = CommonData.mockProcessArgs;
    const senderName = CommonData.sender.name;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Test 1'],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);

      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
    });
  });
});
