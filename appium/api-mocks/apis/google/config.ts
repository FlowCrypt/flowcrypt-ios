import { KeyUtil, KeyInfoWithIdentityAndOptionalPp } from '../../../api-mocks/core/crypto/key';

export type TestKeyInfo = {
  title: string, passphrase: string, armored: string | null, longid: string | null
};

interface TestSecretsInterface {
  ci_admin_token: string;
  auth: { google: { email: string, password?: string, secret_2fa?: string }[], };
  keys: TestKeyInfo[];
}

export class Config {

  public static extensionId = '';

  private static _secrets: TestSecretsInterface;

  // public static secrets = (): TestSecretsInterface => {
  //   if (!Config._secrets) {
  //     try {
  //       Config._secrets = JSON.parse(fs.readFileSync('test/test-secrets.json', 'utf8'));
  //       Config._secrets.keys = testKeyConstants.keys;
  //     } catch (e) {
  //       console.error(`skipping loading test secrets because ${e}`);
  //       Config._secrets = { auth: { google: [] }, keys: [] } as any as TestSecretsInterface;
  //     }
  //   }
  //   return Config._secrets;
  // };

  // public static key = (title: string) => {
  //   return Config.secrets().keys.filter(k => k.title === title)[0];
  // };

  public static getKeyInfo = async (titles: string[]): Promise<KeyInfoWithIdentityAndOptionalPp[]> => {
    return await Promise.all(Config._secrets.keys
      .filter(key => key.armored && titles.includes(key.title)).map(async key => {
        const parsed = await KeyUtil.parse(key.armored!);
        return { ...await KeyUtil.keyInfoObj(parsed), passphrase: key.passphrase };
      }));
  };

}