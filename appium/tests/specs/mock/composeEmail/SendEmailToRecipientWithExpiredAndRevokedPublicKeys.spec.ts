import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import BaseScreen from "../../../screenobjects/base.screen";
import { MockApi } from 'api-mocks/mock';
import { MockUserList } from 'api-mocks/mock-data';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('COMPOSE EMAIL: ', () => {

  it('sending message to user with expired/revoked public key produces modal', async () => {
    const contactWithExpiredKey = MockUserList.expired;
    const contactWithRevokedKey = MockUserList.revoked;

    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const expiredPublicKeyError = CommonData.errors.expiredPublicKey;
    const revokedPublicKeyError = CommonData.errors.revokedPublicKey;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [contactWithExpiredKey, contactWithRevokedKey],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [contactWithExpiredKey.email]: contactWithExpiredKey.pub!,
        [contactWithRevokedKey.email]: contactWithRevokedKey.pub!
      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(contactWithExpiredKey.email, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [contactWithExpiredKey.name],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();

      await BaseScreen.checkModalMessage(expiredPublicKeyError);

      await BaseScreen.clickOkButtonOnError();
      await NewMessageScreen.clickBackButton();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.composeEmail(contactWithRevokedKey.email, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [contactWithRevokedKey.name],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();

      await BaseScreen.checkModalMessage(revokedPublicKeyError);
    });
  });
});
