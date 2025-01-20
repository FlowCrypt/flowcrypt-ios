import { SplashScreen, SetupKeyScreen, MailFolderScreen, NewMessageScreen } from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from '../../../screenobjects/base.screen';
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {
  it('user should enter correct email address into recipients', async () => {
    const invalidRecipient = 'abc';
    const recipient = MockUserList.dmitry;
    const subject = CommonData.simpleEmail.subject;
    const message = CommonData.simpleEmail.message;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
      },
    };

    const invalidRecipientError = CommonData.errors.invalidRecipient;
    const oneOrMoreInvalidRecipientError = CommonData.errors.oneOrMoreInvalidRecipient;

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient(invalidRecipient);
      await BaseScreen.checkModalMessage(invalidRecipientError);
      await BaseScreen.clickOkButtonOnError();

      await NewMessageScreen.deleteEnteredRecipient(invalidRecipient);
      await NewMessageScreen.composeEmail(recipient.email, subject, message);
      await NewMessageScreen.setAddRecipient(invalidRecipient);
      await BaseScreen.checkModalMessage(invalidRecipientError);
      await BaseScreen.clickOkButtonOnError();

      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(oneOrMoreInvalidRecipientError);
      await BaseScreen.clickOkButtonOnError();
    });
  });
});
