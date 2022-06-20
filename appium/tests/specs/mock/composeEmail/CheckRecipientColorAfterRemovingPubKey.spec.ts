import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
  ContactScreen,
  ContactPublicKeyScreen,
  SettingsScreen,
  MenuBarScreen,
  PublicKeyDetailsScreen
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import PublicKeyHelper from "../../../helpers/PublicKeyHelper";
import { MockApi } from 'api-mocks/mock';

describe('COMPOSE EMAIL: ', () => {

  it('check recipient color after removing public key from settings', async () => {
    const contactEmail = CommonData.contact.email;
    const contactName = CommonData.contact.contactName;

    await MockApi.e2eMock.withMockedApis(async () => {
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await MailFolderScreen.checkInboxScreen();

      await PublicKeyHelper.addRecipientAndCheckFetchedKey(contactName, contactEmail);

      await PublicKeyDetailsScreen.clickTrashButton();
      await ContactPublicKeyScreen.checkPgpUserId(contactEmail, contactName);
      await ContactPublicKeyScreen.checkPublicKeyDetailsNotDisplayed();
      await ContactPublicKeyScreen.clickBackButton();

      await ContactScreen.checkContactWithoutPubKey(contactEmail);
      await ContactScreen.clickBackButton();
      await SettingsScreen.checkSettingsScreen();

      await MenuBarScreen.clickMenuBtn();
      await MenuBarScreen.checkUserEmail();
      await MenuBarScreen.clickInboxButton();
      await MailFolderScreen.checkInboxScreen();

      await PublicKeyHelper.addRecipientAndCheckFetchedKey(contactName, contactEmail);
    });
  });
});
