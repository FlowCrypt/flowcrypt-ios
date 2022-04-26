import { MockApi } from 'api-mocks/mock';
import {
    SplashScreen,
    SetupKeyScreen,
} from '../../../screenobjects/all-screens';
import {attesterPublicKeySamples} from "../../../../api-mocks/apis/attester/attester-endpoints";
import {ekmPrivateKeySamples} from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import BaseScreen from "../../../screenobjects/base.screen";
import {CommonData} from "../../../data";


describe('SETUP: ', () => {

  it('test that returns only revoked key from EKM during setup', async () => {

    const mockApi = new MockApi();
    const noPrivateKeyError = CommonData.errors.noPrivateKey;
    const recipientEmail = CommonData.recipient.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: "http://127.0.0.1:8001/ekm",
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        'robot@flowcrypt.com': attesterPublicKeySamples.valid
      }
    };

    mockApi.ekmConfig = {
      returnKeys: [ekmPrivateKeySamples.revokedPrv]
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.login();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.composeEmail(recipientEmail, emailSubject, emailText);
      await NewMessageScreen.checkFilledComposeEmailInfo({
        recipients: [recipientEmail],
        subject: emailSubject,
        message: emailText
      });
      await NewMessageScreen.clickSendButton();
      await BaseScreen.checkModalMessage(noPrivateKeyError);
    });
  });
});
