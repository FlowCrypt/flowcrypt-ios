import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  MenuBarScreen
} from '../../../screenobjects/all-screens';

import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import BaseScreen from 'tests/screenobjects/base.screen';

describe('INBOX: ', () => {

  it('should show appropriate swipe actions', async () => {
    const mockApi = new MockApi();

    const subject1 = 'CC and BCC test';
    const subject2 = 'Test 1';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject1, subject2],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // archive thread
      await MailFolderScreen.tapSwipeAction(subject1, 'leading');
      await MailFolderScreen.checkEmailIsNotDisplayed(subject1);

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickAllMailButton();
      await MailFolderScreen.checkEmailIsDisplayed(subject1);

      // unarchive thread
      await MailFolderScreen.tapSwipeAction(subject1, 'leading');
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.checkEmailIsDisplayed(subject1);

      // move thread to trash
      await MailFolderScreen.tapSwipeAction(subject2, 'trailing');
      await MailFolderScreen.checkEmailIsNotDisplayed(subject2);
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickTrashButton();
      await MailFolderScreen.checkTrashScreen();
      await MailFolderScreen.checkEmailIsDisplayed(subject2);

      // permanently delete thread
      await MailFolderScreen.tapSwipeAction(subject2, 'trailing');
      await BaseScreen.clickCancelButton();
      await MailFolderScreen.checkEmailIsDisplayed(subject2);

      await MailFolderScreen.tapSwipeAction(subject2, 'trailing');
      await BaseScreen.clickConfirmButton();
      await MailFolderScreen.checkEmailIsNotDisplayed(subject2);

      await MailFolderScreen.refreshMailList();
      await MailFolderScreen.checkEmailIsNotDisplayed(subject2);
    });
  });
});
