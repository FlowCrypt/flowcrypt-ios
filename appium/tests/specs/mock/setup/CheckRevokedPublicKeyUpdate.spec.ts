import { ekmKeySamples } from 'api-mocks/apis/ekm/ekm-endpoints';
import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen
} from '../../../screenobjects/all-screens';
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";

describe('SETUP: ', () => {

  it('will not update a revoked public key with valid one', async () => {

    const mockApi = MockApi.e2eMock;
    const contactEmail = 'available.on@attester.test';
    const contactName = 'Test1';

    mockApi.attesterConfig = {
      servedPubkeys: {
        [contactEmail]: ekmKeySamples.key0Revoked.pub!
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2e.prv]
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient(contactEmail);
      await NewMessageScreen.checkAddedRecipientColor(contactName, 0, 'red');

      mockApi.attesterConfig = {
        servedPubkeys: {
          [contactEmail]: ekmKeySamples.key0Updated.pub!
        }
      };

      await NewMessageScreen.deleteAddedRecipient(0);

      // Should display name in red background(which means revoked key) even though we receive new updated key
      // Because we already have revoked key on local
      await NewMessageScreen.setAddRecipient(contactEmail);
      await NewMessageScreen.checkAddedRecipientColor(contactName, 0, 'red');

      // Now check if other functioning key (different fingerprint than revoked one) works fine
      mockApi.attesterConfig = {
        servedPubkeys: {
          [contactEmail]: ekmKeySamples.key1.pub!
        }
      };
      await NewMessageScreen.deleteAddedRecipient(0);
      await NewMessageScreen.setAddRecipient(contactEmail);
      await NewMessageScreen.checkAddedRecipientColor(contactName, 0, 'green');
    });
  });
});
