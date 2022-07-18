import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { CommonData } from "../../../data";
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('SETUP: ', () => {

  it('test that has one revoked key followed by one valid key returned by EKM during setup', async () => {

    const mockApi = new MockApi();

    const recipient = MockUserList.robot;
    const emailSubject = CommonData.revokeValidMessage.subject;
    const emailText = CommonData.revokeValidMessage.message;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eRevokedKey.prv, ekmKeySamples.e2e.prv]
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!
      }
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.composeEmail(recipient.email, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipient.name],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkInboxScreen();
    });
  });
});
