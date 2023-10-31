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
import BaseScreen from 'tests/screenobjects/base.screen';
import { CommonData } from 'tests/data';

describe('COMPOSE EMAIL: ', () => {
  it('check encrypting message for user which contains sign only key', async () => {
    const mockApi = new MockApi();

    const recipient = MockUserList.robot;
    const subject = 'sign only key subject';
    const message = 'sign only key message';
    const unUsuableEncryptionPublicKeyError = CommonData.errors.unUsuableEncryptionPublicKey;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com');
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pubSignOnly!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      // Stage1: Try to compose message with sign only key and check if proper error message is shown
      await NewMessageScreen.composeEmail(recipient.email, subject, message);
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(unUsuableEncryptionPublicKeyError);
      await BaseScreen.clickOkButtonOnError();

      // Stage2: Now try to encrypt & send message for user which contains sign only key & normal key and check if message is sent correctly
      mockApi.attesterConfig = {
        servedPubkeys: {
          [recipient.email]: `${recipient.pub!}\n${recipient.pubSignOnly}`,
        },
      };
      await NewMessageScreen.deleteAddedRecipient(0);
      await NewMessageScreen.setAddRecipient(recipient.email);
      await NewMessageScreen.clickSendButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.checkSentScreen();
      await MailFolderScreen.clickOnEmailBySubject(subject);
    });
  });
});
