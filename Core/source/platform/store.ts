/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Key } from 'openpgp';
import { strToHex } from './util';

let KEY_CACHE: { [longidOrArmoredKey: string]: Key } = {};
let KEY_CACHE_WIPE_TIMEOUT: NodeJS.Timeout;

const keyLongid = (k: Key) => strToHex(k.getKeyID().bytes).toUpperCase();

export class Store {
  public static decryptedKeyCacheSet = (k: Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[keyLongid(k)] = k;
  };

  public static decryptedKeyCacheGet = (longid: string): Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[longid];
  };

  public static armoredKeyCacheSet = (armored: string, k: Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[armored] = k;
  };

  public static armoredKeyCacheGet = (armored: string): Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[armored];
  };

  public static keyCacheWipe = () => {
    KEY_CACHE = {};
  };

  private static keyCacheRenewExpiry = () => {
    if (KEY_CACHE_WIPE_TIMEOUT) {
      clearTimeout(KEY_CACHE_WIPE_TIMEOUT);
    }
    KEY_CACHE_WIPE_TIMEOUT = setTimeout(Store.keyCacheWipe, 2 * 60 * 1000);
  };
}
