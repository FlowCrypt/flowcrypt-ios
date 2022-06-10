import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  EmailScreen,
  SearchScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from "../../../../api-mocks/mock";
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { allowedRecipients } from '../../../../api-mocks/apis/google/google-endpoints';
import ElementHelper from 'tests/helpers/ElementHelper';
import { join } from 'path';

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
      allowedRecipients: allowedRecipients
    }

    await mockApi.withMockedApis(async () => {
      await driver.activateApp("com.apple.Preferences");
      await ElementHelper.waitAndClick(await $('~General'));
      await ElementHelper.waitAndClick(await $('~About'));
      await ElementHelper.waitAndClick(await $('~Certificate Trust Settings'));

      await browser.pause(10000);
      const path = join(process.cwd(), './tmp');
      await driver.saveScreenshot(`${path}/certificates.png`);
      // await SplashScreen.mockLogin();
      // await SetupKeyScreen.setPassPhrase();
      // await MailFolderScreen.checkInboxScreen();

      // await MailFolderScreen.clickSearchButton();
      // await SearchScreen.searchAndClickEmailBySubject(emailSubject);

      // await EmailScreen.checkOpenedEmail(senderName, emailSubject, emailText);
      // await EmailScreen.checkRecipientsButton(recipientsButton);
      // await EmailScreen.clickRecipientsButton();
      // await EmailScreen.checkRecipientsList(toLabel, ccLabel, bccLabel);
    });
  });
});
