import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  SettingsScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import { CommonData } from "../../../data";
import ContactScreen from "../../../screenobjects/contacts.screen";
import { MockApi } from 'api-mocks/mock';


describe('SETTINGS: ', () => {

  it('check correct removing contacts', async () => {
    const firstRecipient = CommonData.contact.email;
    const firstRecipientName = CommonData.contact.name;
    const secondRecipient = CommonData.secondContact.email;
    const secondRecipientName = CommonData.secondContact.name;
    const thirdRecipient = CommonData.recipient.email;
    const thirdRecipientName = CommonData.recipient.name;
    const fourthRecipient = CommonData.expiredMockUser.email;
    const fourthRecipientName = CommonData.expiredMockUser.name;
    const fifthRecipient = CommonData.recipientWithRevokedPublicKey.email;
    const fifthRecipientName = CommonData.recipientWithRevokedPublicKey.name;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await MailFolderScreen.clickCreateEmail();
      await NewMessageScreen.setAddRecipient(firstRecipient);
      await NewMessageScreen.setAddRecipient(secondRecipient);
      await NewMessageScreen.setAddRecipient(thirdRecipient);
      await NewMessageScreen.setAddRecipient(fourthRecipient);
      await NewMessageScreen.setAddRecipient(fifthRecipient);
      await NewMessageScreen.checkAddedRecipient(firstRecipientName, 0);
      await NewMessageScreen.checkAddedRecipient(secondRecipientName, 1);
      await NewMessageScreen.checkAddedRecipient(thirdRecipientName, 2);
      await NewMessageScreen.checkAddedRecipient(fourthRecipientName, 3);
      await NewMessageScreen.checkAddedRecipient(fifthRecipientName, 4);

      await NewMessageScreen.clickBackButton();
      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();

      await MenuBarScreen.clickSettingsButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContactOrder(thirdRecipient, 0);
      await ContactScreen.checkContactOrder(fifthRecipient, 1);
      await ContactScreen.checkContactOrder(fourthRecipient, 2);
      await ContactScreen.checkContactOrder(firstRecipient, 3);
      await ContactScreen.checkContactOrder(secondRecipient, 4);

      await ContactScreen.clickRemoveButton(1);

      await ContactScreen.checkContactOrder(thirdRecipient, 0);
      await ContactScreen.checkContactIsNotDisplayed(fifthRecipient, 1);
      await ContactScreen.checkContactOrder(fourthRecipient, 2);
      await ContactScreen.checkContactOrder(firstRecipient, 3);
      await ContactScreen.checkContactOrder(secondRecipient, 4);

      await ContactScreen.clickRemoveButton(3);

      await ContactScreen.checkContactOrder(thirdRecipient, 0);
      await ContactScreen.checkContactIsNotDisplayed(fifthRecipient, 1);
      await ContactScreen.checkContactIsNotDisplayed(firstRecipient, 3);
      await ContactScreen.checkContactOrder(fourthRecipient, 2);
      await ContactScreen.checkContactOrder(secondRecipient, 4);

      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();
      await SettingsScreen.clickOnSettingItem('Contacts');

      await ContactScreen.checkContactScreen();
      await ContactScreen.checkContactOrder(thirdRecipient, 0);
      await ContactScreen.checkContactOrder(fourthRecipient, 1);
      await ContactScreen.checkContactOrder(secondRecipient, 2);
    });
  });
});
