import {
  SplashScreen,
  SetupKeyScreen,
  MenuBarScreen,
  SettingsScreen,
  MailFolderScreen
} from '../../../screenobjects/all-screens';
import NewMessageScreen from "../../../screenobjects/new-message.screen";
import {CommonData} from "../../../data";
import ContactScreen from "../../../screenobjects/contacts.screen";


describe('SETTINGS: ', () => {

  it('check correct removing contacts', async () => {

    const firstRecipient = CommonData.contact.email;
    const secondRecipient = CommonData.secondContact.email;
    const thirdRecipient = CommonData.recipient.email;
    const fourthRecipient = CommonData.recipientWithExpiredPublicKey.email;
    const fifthRecipient = CommonData.recipientWithRevokedPublicKey.email;


    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();
    await NewMessageScreen.setAddRecipient(firstRecipient);
    await NewMessageScreen.setAddRecipient(secondRecipient);
    await NewMessageScreen.setAddRecipient(thirdRecipient);
    await NewMessageScreen.setAddRecipient(fourthRecipient);
    await NewMessageScreen.setAddRecipient(fifthRecipient);
    await NewMessageScreen.checkAddedRecipient(firstRecipient, 0);
    await NewMessageScreen.checkAddedRecipient(secondRecipient, 1);
    await NewMessageScreen.checkAddedRecipient(thirdRecipient, 2);
    await NewMessageScreen.checkAddedRecipient(fourthRecipient, 3);
    await NewMessageScreen.checkAddedRecipient(fifthRecipient, 4);

    await NewMessageScreen.clickBackButton();
    await MenuBarScreen.clickMenuIcon();
    await MenuBarScreen.checkUserEmail();

    await MenuBarScreen.clickSettingsButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContactOrder(thirdRecipient, 0);
    await ContactScreen.checkContactOrder(fifthRecipient, 1);
    await ContactScreen.checkContactOrder(fourthRecipient, 2);
    await ContactScreen.checkContactOrder(firstRecipient, 3);
    await ContactScreen.checkContactOrder(secondRecipient,4);

    await ContactScreen.clickRemoveButton(1);

    await ContactScreen.checkContactOrder(thirdRecipient, 0);
    await ContactScreen.checkContractIsNotDispalyed(fifthRecipient, 1);
    await ContactScreen.checkContactOrder(fourthRecipient, 2);
    await ContactScreen.checkContactOrder(firstRecipient, 3);
    await ContactScreen.checkContactOrder(secondRecipient,4);

    await ContactScreen.clickRemoveButton(3);

    await ContactScreen.checkContactOrder(thirdRecipient, 0);
    await ContactScreen.checkContractIsNotDispalyed(fifthRecipient, 1);
    await ContactScreen.checkContractIsNotDispalyed(firstRecipient, 3);
    await ContactScreen.checkContactOrder(fourthRecipient, 2);
    await ContactScreen.checkContactOrder(secondRecipient,4);

    await ContactScreen.clickBackButton();
    await SettingsScreen.checkSettingsScreen();
    await SettingsScreen.clickOnSettingItem('Contacts');

    await ContactScreen.checkContactScreen();
    await ContactScreen.checkContactOrder(thirdRecipient, 0);
    await ContactScreen.checkContactOrder(fourthRecipient, 1);
    await ContactScreen.checkContactOrder(secondRecipient,2);
  });
});
