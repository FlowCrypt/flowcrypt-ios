import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import {
  EmailScreen,
  MailFolderScreen, MenuBarScreen, NewMessageScreen,
  SetupKeyScreen,
  SplashScreen
} from '../../../screenobjects/all-screens';

describe('COMPOSE EMAIL: ', () => {

  it('check drafts functionality', async () => {
    const mockApi = new MockApi();

    const recipient = MockUserList.robot;
    const subject = 'Test 1';
    const draftSubject = "Draft subject";
    const draftText1 = 'Draft text';
    const updatedDraftText = 'Some new text';
    const draftText2 = 'Another draft';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.robot.email]: MockUserList.robot.pub!
      }
    };

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

      await EmailScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient.email, draftSubject, draftText1);
      await NewMessageScreen.clickBackButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickDraftsButton();
      await MailFolderScreen.clickOnEmailBySubject(draftSubject);
      await NewMessageScreen.clickSendButton();
      await NewMessageScreen.clickBackButton();
      await MailFolderScreen.checkIfFolderIsEmpty();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.clickOnEmailBySubject(draftSubject);

      await browser.pause(600000);
    });
  });
});