/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { Key } from '../core/crypto/key';

export class KeyCache {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public static setDecrypted = (k: Key) => {
    // tests don't need this
  };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public static getDecrypted = (longid: string): Key | undefined => {
    return undefined; // tests don't need this
  };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public static setArmored = (armored: string, k: Key) => {
    // tests don't need this
  };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public static getArmored = (armored: string): Key | undefined => {
    return undefined; // tests don't need this
  };
}
