import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";
import { MockApi } from 'api-mocks/mock';

describe('COMPOSE EMAIL: ', () => {

  it('user should enter correct email address into recipients', async () => {

    const invalidRecipientError = CommonData.errors.invalidRecipient;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient('abc');
      await BaseScreen.checkModalMessage(invalidRecipientError);
      await BaseScreen.clickOkButtonOnError();
    });
  });
});
