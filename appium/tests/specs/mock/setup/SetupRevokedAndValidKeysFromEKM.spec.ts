import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
} from '../../../screenobjects/all-screens';
import { attesterPublicKeySamples } from "../../../../api-mocks/apis/attester/attester-endpoints";
import { ekmPrivateKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import MailFolderHelper from 'tests/helpers/MailFolderHelper';
import { CommonData } from "../../../data";


describe('SETUP: ', () => {

  it('test that has one revoked key followed by one valid key returned by EKM during setup', async () => {

    const mockApi = new MockApi();
    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const emailSubject = CommonData.revokeValidMessage.subject;
    const emailText = CommonData.revokeValidMessage.message;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        'robot@flowcrypt.com': attesterPublicKeySamples.valid
      }
    };

    mockApi.ekmConfig = {
      returnKeys: [ekmPrivateKeySamples.e2eRevokedKey.prv, ekmPrivateKeySamples.e2eValidKey.prv]
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
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

      await MailFolderHelper.deleteSentEmail(emailSubject, emailText);
    });
  });
});
