import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  NewMessageScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SettingsScreen,
  MenuBarScreen,
  PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';

import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';

describe('COMPOSE EMAIL: ', () => {

  it('user is able to select recipient from contact list using contact name', async () => {

    const firstContact = MockUserList.dmitry;
    const secondContact = MockUserList.demo;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.googleConfig = {
      accounts: {
        'e2e.enterprise.test@flowcrypt.com': {
          contacts: [firstContact, secondContact],
          messages: [],
        }
      }
    };
    mockApi.attesterConfig = {
      servedPubkeys: {
        [firstContact.email]: firstContact.pub!,
        [secondContact.email]: secondContact.pub!
      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      // Go to Contacts screen
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkEmptyList();
      await ContactScreen.clickBackButton();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.checkInboxScreen();

      // Add first contact
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipientByName(firstContact.name, firstContact.email);
      await NewMessageScreen.checkAddedRecipient(firstContact.name);
      await NewMessageScreen.clickBackButton();

      // Add second contact
      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipientByName(secondContact.name, secondContact.email);
      await NewMessageScreen.checkAddedRecipient(secondContact.name);
      await NewMessageScreen.clickBackButton();

      // Go to Contacts screen
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContact(firstContact.name);
      await ContactScreen.checkContact(secondContact.name);

      // Go to Contact screen
      await ContactScreen.clickOnContact(firstContact.name);

      await ContactPublicKeyScreen.checkPgpUserId(firstContact.email, firstContact.name);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotEmpty();
      await ContactPublicKeyScreen.clickOnFingerPrint();
      await PublicKeyDetailsScreen.checkPublicKeyDetailsScreen();
      await PublicKeyDetailsScreen.checkPublicKeyNotEmpty();
    });
  });
});
