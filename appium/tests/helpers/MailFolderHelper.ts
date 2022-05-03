import MailFolderScreen from "../screenobjects/mail-folder.screen";


class MailFolderHelper {

  static checkPagination = async (subject: string) => {
    const emailsCountBeforeScroll = await MailFolderScreen.getEmailCount();
    await MailFolderScreen.scrollDownToEmail(subject);
    expect(emailsCountBeforeScroll).toEqual(20);

    const emailsCountAfterScroll = await MailFolderScreen.getEmailCount();
    expect(emailsCountBeforeScroll).toBeLessThan(emailsCountAfterScroll);
  }
}
export default MailFolderHelper;
