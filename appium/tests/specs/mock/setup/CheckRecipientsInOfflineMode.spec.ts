import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';
import { MockApi } from "../../../../api-mocks/mock";
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('check valid, revoked and expired recipients in offline mode', async () => {

    const validRecipient = MockUserList.dmitry;
    const expiredRecipient = MockUserList.expired;
    const revokedRecipient = MockUserList.revoked;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.dmitry.email]: MockUserList.dmitry.pub!,
        [MockUserList.expired.email]: MockUserList.expired.pub!,
        [MockUserList.revoked.email]: MockUserList.revoked.pub!,
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(validRecipient.email);
      await NewMessageScreen.setAddRecipient(expiredRecipient.email);
      await NewMessageScreen.setAddRecipient(revokedRecipient.email);

      await NewMessageScreen.checkAddedRecipientColor(validRecipient.name, 0, 'green');
      await NewMessageScreen.checkAddedRecipientColor(expiredRecipient.name, 1, 'orange');
      await NewMessageScreen.checkAddedRecipientColor(revokedRecipient.name, 2, 'red');

      await NewMessageScreen.deleteAddedRecipient(2);
      await NewMessageScreen.deleteAddedRecipient(1);
      await NewMessageScreen.deleteAddedRecipient(0);


      mockApi.attesterConfig = {
        returnError: {
          code: 400,
          message: "some client err"
        }
      };

      await NewMessageScreen.setAddRecipient(validRecipient.email);
      await NewMessageScreen.setAddRecipient(expiredRecipient.email);
      await NewMessageScreen.setAddRecipient(revokedRecipient.email);

      await NewMessageScreen.checkAddedRecipientColor(validRecipient.name, 0, 'green');
      await NewMessageScreen.checkAddedRecipientColor(expiredRecipient.name, 1, 'red');
      await NewMessageScreen.checkAddedRecipientColor(revokedRecipient.name, 2, 'red');
    });
  });
});
