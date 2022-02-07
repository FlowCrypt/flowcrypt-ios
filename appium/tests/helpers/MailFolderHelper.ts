import MailFolderScreen from "../screenobjects/mail-folder.screen";


class MailFolderHelper {

  static checkPagination = async (subject: string) => {
    let emailsCountBeforeScroll = await MailFolderScreen.getEmailCount();
    await MailFolderScreen.scrollDownToEmail(subject);
    expect(emailsCountBeforeScroll).toEqual(40); //Should be changed to 20 when https://github.com/FlowCrypt/flowcrypt-ios/issues/1366 is fixed

    let emailsCountAfterScroll = await MailFolderScreen.getEmailCount();
    expect(emailsCountBeforeScroll).toBeLessThan(emailsCountAfterScroll);
  }
}
export default MailFolderHelper;
