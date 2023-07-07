import { CommonData } from 'tests/data';
import { MailFolderScreen, EmailScreen, MenuBarScreen } from '../screenobjects/all-screens';

class MailFolderHelper {
  static checkPagination = async (subject: string) => {
    const emailsCountBeforeScroll = await MailFolderScreen.getEmailCount();
    await MailFolderScreen.scrollDownToEmail(subject);
    expect(emailsCountBeforeScroll).toEqual(20);

    const emailsCountAfterScroll = await MailFolderScreen.getEmailCount();
    expect(emailsCountBeforeScroll).toBeLessThan(emailsCountAfterScroll);
  };

  static deleteSentEmail = async (subject: string, message: string, sender = CommonData.account.email) => {
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.clickSentButton();
    await MailFolderScreen.checkSentScreen();

    //Check sent email
    await MailFolderScreen.clickOnEmailBySubject(subject);
    await EmailScreen.checkOpenedEmail(sender, subject, message);
    //Delete sent email
    await EmailScreen.clickDeleteButton();
    await MailFolderScreen.checkSentScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(subject);
    await browser.pause(2000); // give Google API time to process the deletion
    await MailFolderScreen.refreshMailList();
    await MailFolderScreen.checkSentScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(subject);
    //Check email in Trash list
    await MenuBarScreen.clickMenuBtn();
    await MenuBarScreen.clickTrashButton();
    await MailFolderScreen.checkTrashScreen();
    await MailFolderScreen.clickOnEmailBySubject(subject);
    //Remove from Trash
    await EmailScreen.clickDeleteButton();
    await EmailScreen.confirmDelete();
    await MailFolderScreen.checkTrashScreen();
    await browser.pause(2000); // give Google API time to process the deletion
    await MailFolderScreen.refreshMailList();
    await MailFolderScreen.checkTrashScreen();
    await MailFolderScreen.checkEmailIsNotDisplayed(subject);
  };
}
export default MailFolderHelper;
