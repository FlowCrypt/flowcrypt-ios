import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { CommonData } from "../../../data";

describe('SETUP: ', () => {

  it('test that has one revoked key followed by one valid key returned by EKM during setup', async () => {

    const mockApi = MockApi.e2eMock;
    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const emailSubject = CommonData.revokeValidMessage.subject;
    const emailText = CommonData.revokeValidMessage.message;

    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eRevokedKey.prv, ekmKeySamples.e2eValidKey.prv]
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipientName],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();
      await MailFolderScreen.checkInboxScreen();
    });
  });
});
