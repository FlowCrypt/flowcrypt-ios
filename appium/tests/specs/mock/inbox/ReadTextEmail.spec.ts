import { SplashScreen, SetupKeyScreen, MailFolderScreen, EmailScreen } from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import { MockApi } from '../../../../api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

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

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['CC and BCC test'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.flowcryptCompatibility.email]: MockUserList.flowcryptCompatibility.pub!,
        [MockUserList.robot.email]: MockUserList.robot.pub!,
        [MockUserList.e2e.email]: MockUserList.e2e.pub!,
      },
    };

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
