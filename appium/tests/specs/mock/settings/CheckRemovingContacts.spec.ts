import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  SettingsScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import ContactScreen from "../../../screenobjects/contacts.screen";
import { MockApi } from 'api-mocks/mock';
import { MockApiConfig } from 'api-mocks/mock-config';
import { MockUserList } from 'api-mocks/mock-data';


describe('SETTINGS: ', () => {

  it('check correct removing contacts', async () => {
    const recipient1 = MockUserList.dmitry;
    const recipient2 = MockUserList.demo;
    const recipient3 = MockUserList.robot;
    const recipient4 = MockUserList.expired;
    const recipient5 = MockUserList.revoked;

    const mockApi = new MockApi();

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      contacts: [recipient1, recipient2, recipient3, recipient4, recipient5],
    });
    mockApi.attesterConfig = {
      servedPubkeys: {
        [recipient1.email]: recipient1.pub!,
        [recipient2.email]: recipient2.pub!,
        [recipient3.email]: recipient3.pub!,
        [recipient4.email]: recipient4.pub!,
        [recipient5.email]: recipient5.pub!,
      }
    };
    mockApi.wkdConfig = {}

    await mockApi.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();

      await NewMessageScreen.setAddRecipient(recipient1.email);
      await NewMessageScreen.setAddRecipient(recipient2.email);
      await NewMessageScreen.setAddRecipient(recipient3.email);
      await NewMessageScreen.setAddRecipient(recipient4.email);
      await NewMessageScreen.setAddRecipient(recipient5.email);

      await NewMessageScreen.checkAddedRecipient(recipient1.name, 0);
      await NewMessageScreen.checkAddedRecipient(recipient2.name, 1);
      await NewMessageScreen.checkAddedRecipient(recipient3.name, 2);
      await NewMessageScreen.checkAddedRecipient(recipient4.name, 3);
      await NewMessageScreen.checkAddedRecipient(recipient5.name, 4);

      await NewMessageScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContactOrder(recipient3.email, 0);
      await ContactScreen.checkContactOrder(recipient5.email, 1);
      await ContactScreen.checkContactOrder(recipient4.email, 2);
      await ContactScreen.checkContactOrder(recipient1.email, 3);
      await ContactScreen.checkContactOrder(recipient2.email, 4);

      await ContactScreen.clickRemoveButton(1);

      await ContactScreen.checkContactOrder(recipient3.email, 0);
      await ContactScreen.checkContactIsNotDisplayed(recipient5.email, 1);
      await ContactScreen.checkContactOrder(recipient4.email, 2);
      await ContactScreen.checkContactOrder(recipient1.email, 3);
      await ContactScreen.checkContactOrder(recipient2.email, 4);

      await ContactScreen.clickRemoveButton(3);

      await ContactScreen.checkContactOrder(recipient3.email, 0);
      await ContactScreen.checkContactIsNotDisplayed(recipient5.email, 1);
      await ContactScreen.checkContactIsNotDisplayed(recipient1.email, 3);
      await ContactScreen.checkContactOrder(recipient4.email, 2);
      await ContactScreen.checkContactOrder(recipient2.email, 4);

      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContactOrder(recipient3.email, 0);
      await ContactScreen.checkContactOrder(recipient4.email, 1);
      await ContactScreen.checkContactOrder(recipient2.email, 2);
    });
  });
});
