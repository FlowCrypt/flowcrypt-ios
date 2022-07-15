import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
  SetupKeyScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import BaseScreen from "../../../screenobjects/base.screen";
import { CommonData } from "../../../data";
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';


describe('SETUP: ', () => {

  it('test that returns only revoked key from EKM during setup', async () => {

    const mockApi = new MockApi();

    const recipientEmail = CommonData.recipient.email;
    const recipientName = CommonData.recipient.name;
    const emailSubject = CommonData.simpleEmail.subject;
    const emailText = CommonData.simpleEmail.message;

    // When private key is revoked key, there are no public keys to pick. So missing sender public key error occurs.
    const noPrivateKeyError = 'Error\n' +
      'Could not compose message\n\n' +
      'Your account keys are not usable for encryption.';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eRevokedKey.prv]
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.robot.email]: MockUserList.robot.pub!
      }
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
      await BaseScreen.checkModalMessage(noPrivateKeyError);
    });
  });
});
