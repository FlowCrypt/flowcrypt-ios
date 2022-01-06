import {
    SplashScreen,
    SetupKeyScreen,

} from '../../../screenobjects/all-screens';
import BaseScreen from "../../../screenobjects/base.screen";
import {CommonData} from "../../../data";


describe('LOGIN: ', () => {

  it('user should be able login to multiple accounts', async () => {

    const wrongPassPhrase = 'wrong';
    const wrongPassPhraseError = CommonData.errors.wrongPassPhraseOnLogin;

    await SplashScreen.loginToOtherEmailProvider();
    await SetupKeyScreen.setPassPhraseForOtherProviderEmail(wrongPassPhrase);
    await BaseScreen.checkModalMessage(wrongPassPhraseError);
    await BaseScreen.clickOkButtonOnError();
    await SetupKeyScreen.setPassPhraseForOtherProviderEmail();
    await BaseScreen.checkModalMessage(wrongPassPhraseError);
  });
});
