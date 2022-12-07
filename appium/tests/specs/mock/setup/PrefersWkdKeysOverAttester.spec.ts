import { MockApi } from 'api-mocks/mock';
import {
  SplashScreen,
} from '../../../screenobjects/all-screens';
import SetupKeyScreen from "../../../screenobjects/setup-key.screen";
import MailFolderScreen from "../../../screenobjects/mail-folder.screen";
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import AppiumHelper from 'tests/helpers/AppiumHelper';
import { CommonData } from 'tests/data';

describe('SETUP: ', () => {

  it('prefers wkd keys over attester keys', async () => {
    const mockApi = new MockApi();
    const recipient = MockUserList.demo;
    const recipientPrefix = recipient.email.split('@')[0];
    const processArgs = CommonData.mockProcessArgs;

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient.email]: recipient.pub!,
      }
    }

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(recipient.email);
      await NewMessageScreen.checkAddedRecipientColor(recipient.name, 0, 'orange');

      mockApi.wkdConfig = {
        servedPubkeys: {
          [recipientPrefix]: recipient.pubOther!,
        }
      }

      await AppiumHelper.restartApp(processArgs);
      await MailFolderScreen.checkInboxScreen();
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(recipient.email);
      await NewMessageScreen.checkAddedRecipientColor(recipient.name, 0, 'green');
    });
  });
});
