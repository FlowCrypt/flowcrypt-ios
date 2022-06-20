import { MockApi } from 'api-mocks/mock';
import { MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen } from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check recipient evaluation when user taps outside the search area', async () => {

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.checkRecipientEvaluationWhenTapOutside();
    });
  });
});
