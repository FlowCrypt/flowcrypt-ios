import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { SplashScreen, SetupKeyScreen, MailFolderScreen, MenuBarScreen } from '../../../screenobjects/all-screens';
import BaseScreen from 'tests/screenobjects/base.screen';

describe('INBOX: ', () => {
  it('user is able select multiple threads and perform actions', async () => {
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Test 1', 'Signed only message', 'email with text attachment'],
    });

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Stage1: Select 2 threads and mark them as read/unread
      await MailFolderScreen.selectThread(0);
      await MailFolderScreen.selectThread(1);
      await MailFolderScreen.clickOnUnreadButton();
      await browser.pause(200);
      await MailFolderScreen.selectThread(0);
      await MailFolderScreen.selectThread(1);
      await MailFolderScreen.clickOnReadButton();
      await browser.pause(200);

      // Stage2: Select 2 threads and move them to trash and check if remaining thread count is one
      await MailFolderScreen.selectThread(0);
      await MailFolderScreen.selectThread(1);
      await MailFolderScreen.clickOnDeleteButton();
      await browser.pause(200);
      await MailFolderScreen.checkEmailCount(1);

      // Stage3: Go to trash and completely remove them
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickTrashButton();
      await MailFolderScreen.selectThread(0);
      await MailFolderScreen.selectThread(1);
      await MailFolderScreen.clickOnDeleteButton();
      await BaseScreen.clickConfirmButton();
      await browser.pause(200);
      await MailFolderScreen.checkIfFolderIsEmpty();
    });
  });
});
