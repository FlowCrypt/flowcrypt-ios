import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from "../../../../api-mocks/mock";
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { GoogleMockMessage } from 'api-mocks/lib/configuration-types';

describe('INBOX: ', () => {

  it('user is able to view text email and recipients list', async () => {

    const senderName = CommonData.recipientsListEmail.senderName;
    const emailSubject = CommonData.recipientsListEmail.subject;
    const emailText = CommonData.recipientsListEmail.message;
    const recipientsButton = CommonData.recipientsListEmail.recipients;
    const toLabel = CommonData.recipientsListEmail.to;
    const ccLabel = CommonData.recipientsListEmail.cc;
    const bccLabel = CommonData.recipientsListEmail.bcc;

    const mockApi = new MockApi();
    mockApi.fesConfig = {
      clientConfiguration: {
        flags: ["NO_PRV_CREATE", "NO_PRV_BACKUP", "NO_ATTESTER_SUBMIT", "PRV_AUTOIMPORT_OR_AUTOGEN", "FORBID_STORING_PASS_PHRASE"],
        key_manager_url: CommonData.keyManagerURL.mockServer,
      }
    };
    mockApi.ekmConfig = {
      returnKeys: [ekmKeySamples.e2eValidKey.prv]
    }
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          messages: [GoogleMockMessage.CcAndBccTest],
        }
      }
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject);

      await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      await EmailScreen.checkRecipientsButton(recipientsButton);
      await EmailScreen.clickRecipientsButton();
      await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
    });
  });
});
