import {MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check recipient evaluation when user taps outside the search area', async () => {

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();

    await NewMessageScreen.checkRecipientEvaluationWhenTapOutside();
  });
});
