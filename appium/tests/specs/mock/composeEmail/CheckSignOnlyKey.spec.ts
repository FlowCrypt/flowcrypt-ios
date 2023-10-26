import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import {
  MailFolderScreen,
  MenuBarScreen,
  NewMessageScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {
  it('check encrypting message for user which contains sign only key', async () => {
    const mockApi = new MockApi();

    const recipient = MockUserList.signOnlyKey;
    const subject = 'sign only key subject';
    const message = 'sign only key message';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com');
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.signOnlyKey.email]: MockUserList.signOnlyKey.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      // Compose draft
      await NewMessageScreen.composeEmail(recipient.email, subject, message);
      await NewMessageScreen.clickBackButton();

      // Go to draft folder
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickDraftsButton();

      // Open draft and see if draft is saved correctly
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient.name],
        subject: subject,
        message: message,
      });
    });
  });
});
