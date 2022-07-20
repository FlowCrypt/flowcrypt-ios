import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";
import MailFolderHelper from 'tests/helpers/MailFolderHelper';
import { MockApi } from 'api-mocks/mock';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to send encrypted email when pass phrase session ended + move to trash, delete', async () => {

    const contact = MockUserList.dmitry;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const passPhrase = CommonData.account.passPhrase;
    const wrongPassPhraseError = CommonData.errors.wrongPassPhrase;
    const wrongPassPhrase = "wrong";
    const processArgs = CommonData.mockProcessArgs;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [contact],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [contact.email]: contact.pub!,
        [MockUserList.e2e.email]: MockUserList.e2e.pub!
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Restart app to reset pass phrase memory cache
      await AppiumHelper.restartApp(processArgs);

      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(contact.email, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [contact.name],
        subject: emailSubject,
        message: emailText
      });

      // Set wrong pass phrase and check error
      await NewMessageScreen.clickSendButton();
      await EmailScreen.enterPassPhrase(wrongPassPhrase);
      await EmailScreen.clickOkButton();
      await BaseScreen.checkModalMessage(wrongPassPhraseError);
      await BaseScreen.clickOkButtonOnError();

      // Set correct pass phrase
      await NewMessageScreen.clickSendButton();
      await EmailScreen.enterPassPhrase(passPhrase);
      await EmailScreen.clickOkButton();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderHelper.deleteSentEmail(emailSubject, emailText);
    });
  });
});
