import {
  SplashScreen,
  SetupKeyScreen,
  MailFolderScreen,
} from '../../../screenobjects/all-screens';

import { CommonData } from '../../../data';
import MailFolderHelper from "../../../helpers/MailFolderHelper";

describe('INBOX: ', () => {

  it('check inbox pagination after loading all messages', async () => {

    const firstEmailSubject = CommonData.simpleEmail.subject;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderHelper.checkPagination(firstEmailSubject);

    await MailFolderScreen.scrollUpToFirstEmail();
    await MailFolderScreen.refreshMailList();

    await MailFolderHelper.checkPagination(firstEmailSubject);
  });
});
