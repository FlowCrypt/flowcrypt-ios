import {MailFolderScreen, NewMessageScreen, SetupKeyScreen, SplashScreen} from '../../../screenobjects/all-screens';

import {CommonData} from '../../../data';

describe('COMPOSE EMAIL: ', () => {

  it('check added recipient popup', async () => {

    const recipient1 = CommonData.emailWithMultipleRecipientsWithCC.sender;
    const recipient1Name = CommonData.emailWithMultipleRecipientsWithCC.senderName;
    const recipient2 = CommonData.recipientWithExpiredPublicKey.email;
    const recipient2Name = CommonData.recipientWithExpiredPublicKey.name;
    const recipient3 = CommonData.recipientWithRevokedPublicKey.email;
    const recipient3Name = CommonData.recipientWithRevokedPublicKey.name;

    await SplashScreen.login();
    await SetupKeyScreen.setPassPhrase();
    await MailFolderScreen.checkInboxScreen();

    await MailFolderScreen.clickCreateEmail();

    await NewMessageScreen.setAddRecipient(recipient1);
    await NewMessageScreen.setAddRecipient(recipient2);
    await NewMessageScreen.setAddRecipient(recipient3);

    await NewMessageScreen.checkPopupRecipientInfo(recipient1, 0, 'to', recipient1Name);
    await NewMessageScreen.checkPopupRecipientInfo(recipient2, 1, 'to', recipient2Name);
    await NewMessageScreen.checkPopupRecipientInfo(recipient3, 2, 'to', recipient3Name);

    await NewMessageScreen.checkCopyForAddedRecipient(recipient1, 0);

    await NewMessageScreen.checkEditRecipient(0, 'to', recipient1Name, 3);

    await NewMessageScreen.deleteAddedRecipient(2);
    await NewMessageScreen.deleteAddedRecipientWithBackspace(1);
    await NewMessageScreen.deleteAddedRecipient(0);
  });
});
