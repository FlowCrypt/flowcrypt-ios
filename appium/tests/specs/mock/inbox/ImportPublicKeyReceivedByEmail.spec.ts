import {
  ContactScreen,
  EmailScreen,
  MailFolderScreen,
  MenuBarScreen,
  SettingsScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';

import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';
import { CommonData } from '../../../data';

describe('INBOX: ', () => {
  it('user is able to import public key received by email', async () => {
    const emailSubject = CommonData.encryptedEmailWithPublicKey.subject;
    const publicKeyEmail = CommonData.encryptedEmailWithPublicKey.publicKeyEmail;
    const publicKeyFingerPrint = CommonData.encryptedEmailWithPublicKey.publicKeyFingerPrint;
    const emailSubject2 = CommonData.emailWithAnotherUserPublicKey.subject;
    const publicKeyEmail2 = CommonData.emailWithAnotherUserPublicKey.publicKeyEmail;
    const publicKeyFingerPrint2 = CommonData.emailWithAnotherUserPublicKey.publicKeyFingerPrint;
    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: ['Encrypted email with public key attached', 'Email with another user public key attached'],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [MockUserList.e2e.email]: MockUserList.e2e.pub!,
      },
    };

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickOnEmailBySubject(emailSubject);
      await EmailScreen.checkPublicKeyImportView(publicKeyEmail, publicKeyFingerPrint, false);
      await EmailScreen.importPublicKey();
      await EmailScreen.clickBackButton();

      // Go to Contacts screen and see if pubkey is imported correctly
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.clickOnSettingItem('Contacts');
      await ContactScreen.checkContact(publicKeyEmail);

      // Now go back to inbox screen and check `email with another user pubkey attached`
      await ContactScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject2);
      await EmailScreen.checkPublicKeyImportView(publicKeyEmail2, publicKeyFingerPrint2, false);
      await EmailScreen.importPublicKey();
      // Check if import button changed to `Already imported` after public key is imported
      await EmailScreen.clickBackButton();
      await MailFolderScreen.clickOnEmailBySubject(emailSubject2);
      await EmailScreen.checkPublicKeyImportView(publicKeyEmail2, publicKeyFingerPrint2, true);
    });
  });
});
