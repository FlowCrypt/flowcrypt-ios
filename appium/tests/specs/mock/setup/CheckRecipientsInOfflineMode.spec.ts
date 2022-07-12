import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';
import { CommonData } from '../../../data';
import { MockApi } from "../../../../api-mocks/mock";

describe('COMPOSE EMAIL: ', () => {

  it('check valid, revoked and expired recipients in offline mode', async () => {

    const validEmail = CommonData.validMockUser.email;
    const validName = CommonData.validMockUser.name;
    const expiredEmail = CommonData.expiredMockUser.email;
    const expiredName = CommonData.expiredMockUser.name;
    const revokedEmail = CommonData.revokedMockUser.email;
    const revokedName = CommonData.revokedMockUser.name;

    const mockApi = MockApi.e2eMock

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(validEmail);
      await NewMessageScreen.setAddRecipient(expiredEmail);
      await NewMessageScreen.setAddRecipient(revokedEmail);

      await NewMessageScreen.checkAddedRecipientColor(validName, 0, 'green');
      await NewMessageScreen.checkAddedRecipientColor(expiredName, 1, 'orange');
      await NewMessageScreen.checkAddedRecipientColor(revokedName, 2, 'red');

      await NewMessageScreen.deleteAddedRecipient(2);
      await NewMessageScreen.deleteAddedRecipient(1);
      await NewMessageScreen.deleteAddedRecipient(0);

      mockApi.attesterConfig = {
        returnError: {
          code: 400,
          message: "some client err"
        }
      };

      await NewMessageScreen.setAddRecipient(validEmail);
      await NewMessageScreen.setAddRecipient(expiredEmail);
      await NewMessageScreen.setAddRecipient(revokedEmail);

      await NewMessageScreen.checkAddedRecipientColor(validName, 0, 'green');
      await NewMessageScreen.checkAddedRecipientColor(expiredName, 1, 'red');
      await NewMessageScreen.checkAddedRecipientColor(revokedName, 2, 'red');
    });
  });
});
