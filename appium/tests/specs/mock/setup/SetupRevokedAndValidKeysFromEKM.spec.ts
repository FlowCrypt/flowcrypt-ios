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

  it('test that has one revoked key followed by one valid key returned by EKM during setup', async () => {

    const mockApi = new MockApi();
    const recipientEmail = CommonData.recipient.email;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;
    const ekmURL = CommonData.keyManagerURL.link

    const noPrivateKeyError = 'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'Error: Error encrypting message: Could not find valid key packet for signing in key bf79556b2cad5c1e ' +
      '@ asyncFunctionResume@[native code] @[native code] promiseReactionJobWithoutPromise@[native code] promiseReactionJob@[native code]';


    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: ekmURL,
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        'robot@flowcrypt.com': attesterPublicKeySamples.valid
      }
    };

    mockApi.ekmConfig = {
      returnKeys: [ ekmPrivateKeySamples.revokedPrv ,ekmPrivateKeySamples.existingPrv]
    }

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
      //TODO need to fix, the error should not be displayed for this case
      await BaseScreen.checkModalMessage(noPrivateKeyError);
    });
  });
});
