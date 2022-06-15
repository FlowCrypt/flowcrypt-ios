import { KeyUtil, KeyInfoWithIdentityAndOptionalPp } from '../core/crypto/key';

export type TestKeyInfo = {
  title: string, passphrase: string, armored: string | null, longid: string | null
};

interface TestSecretsInterface {
  ci_admin_token: string;
  auth: { google: { email: string, password?: string, secret_2fa?: string }[], };
  keys: TestKeyInfo[];
}

export class Config {

  private static _secrets: TestSecretsInterface;

  public static getKeyInfo = async (titles: string[]): Promise<KeyInfoWithIdentityAndOptionalPp[]> => {
    return await Promise.all(Config._secrets.keys
      .filter(key => key.armored && titles.includes(key.title)).map(async key => {
        const parsed = await KeyUtil.parse(key.armored!);
        return { ...await KeyUtil.typedKeyInfoObj(parsed), passphrase: key.passphrase };
      }));
  };

}