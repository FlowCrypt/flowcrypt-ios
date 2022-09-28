import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import {
  EmailScreen,
  MailFolderScreen, MenuBarScreen, NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check drafts functionality', async () => {
    const mockApi = new MockApi();
    const subject = 'Test 1';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });

    const draftText1 = 'Draft text';
    const updatedDraftText = 'Some new text';
    const draftText2 = 'Another draft';

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(subject);

      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkMessageFieldFocus();
      await NewMessageScreen.addMessageText(draftText1);
      await NewMessageScreen.clickBackButton();

      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkMessageFieldFocus();
      await NewMessageScreen.addMessageText(draftText2);
      await NewMessageScreen.clickBackButton();

      await EmailScreen.checkDraft(draftText1, 1);
      await EmailScreen.checkDraft(draftText2, 2);

      await EmailScreen.openDraft(1);

      await NewMessageScreen.setComposeSecurityMessage(updatedDraftText);
      await NewMessageScreen.clickBackButton();

      await EmailScreen.checkDraft(updatedDraftText, 1);
      await EmailScreen.checkDraft(draftText2, 2);

      await EmailScreen.deleteDraft(1);
      await EmailScreen.clickBackButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickDraftsButton();

      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkDraft(draftText2, 1);
      await EmailScreen.openDraft(1);

      await NewMessageScreen.clickDeleteButton();
      await NewMessageScreen.confirmDelete();
    });
  });
});

// check passphrase modal after app restart
// check compose new draft is added to drafts folder