import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { CommonData } from 'tests/data';
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
    const recipientWithoutPubKeys = MockUserList.demo;
    const subject = CommonData.simpleEmail.subject;
    const draftSubject = CommonData.draft.subject;
    const draftText1 = CommonData.draft.text1;
    const updatedDraftText = CommonData.draft.updatedText1;
    const draftText2 = CommonData.draft.text2;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Test 1'],
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

      // compose draft as reply to existing thread
      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkMessageFieldFocus();
      await NewMessageScreen.addMessageText(draftText1);
      await NewMessageScreen.clickBackButton();

      // compose another draft
      await EmailScreen.clickReplyButton();
      await NewMessageScreen.checkMessageFieldFocus();
      await NewMessageScreen.addMessageText(draftText2);
      await NewMessageScreen.clickBackButton();

      // check if drafts are added to thread messages
      await EmailScreen.checkDraft(draftText1, 1);
      await EmailScreen.checkDraft(draftText2, 2);

      // update draft and check if changes are applied
      await EmailScreen.openDraft(1);

      await NewMessageScreen.setComposeSecurityMessage(updatedDraftText);
      await NewMessageScreen.clickBackButton();

      await EmailScreen.checkDraft(updatedDraftText, 1);
      await EmailScreen.checkDraft(draftText2, 2);

      // delete draft from thread screen
      await EmailScreen.deleteDraft(1);
      await EmailScreen.clickBackButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickDraftsButton();

      // delete draft from compose screen
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await EmailScreen.checkDraft(draftText2, 1);
      await EmailScreen.openDraft(1);

      await NewMessageScreen.clickDeleteButton();
      await NewMessageScreen.confirmDelete();

      await EmailScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();

      // compose 2 new drafts and then delete them both
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipientWithoutPubKeys.email, draftSubject, draftText1);
      await NewMessageScreen.clickBackButton();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient.email, subject, draftText2);
      await NewMessageScreen.clickBackButton();

      await MailFolderScreen.clickOnEmailBySubject(subject);
      await NewMessageScreen.clickDeleteButton();
      await NewMessageScreen.confirmDelete();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(draftSubject);
      await NewMessageScreen.clickDeleteButton();
      await NewMessageScreen.confirmDelete();

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.checkIfFolderIsEmpty();

      // compose draft, send it and check if sent message added to 'sent' folder
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(recipient.email, draftSubject, draftText1);
      await NewMessageScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickDraftsButton();
      await MailFolderScreen.clickOnEmailBySubject(draftSubject);
      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkIfFolderIsEmpty();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSentButton();
      await MailFolderScreen.clickOnEmailBySubject(draftSubject);
    });
  });
});