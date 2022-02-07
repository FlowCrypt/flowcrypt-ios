/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Key } from '../core/types/openpgp';
import { str_to_hex } from './util';

let KEY_CACHE: { [longidOrArmoredKey: string]: Key } = {};
let KEY_CACHE_WIPE_TIMEOUT: NodeJS.Timeout;

const keyLongid = (k: Key) => str_to_hex(k.getKeyID().bytes).toUpperCase();

export class Store {

  static decryptedKeyCacheSet = (k: Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[keyLongid(k)] = k;
  }

  static decryptedKeyCacheGet = (longid: string): Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[longid];
  }

  static armoredKeyCacheSet = (armored: string, k: Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[armored] = k;
  }

  static armoredKeyCacheGet = (armored: string): Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[armored];
  }

  static keyCacheWipe = () => {
    KEY_CACHE = {};
  }

  private static keyCacheRenewExpiry = () => {
    if (KEY_CACHE_WIPE_TIMEOUT) {
      clearTimeout(KEY_CACHE_WIPE_TIMEOUT);
    }
    KEY_CACHE_WIPE_TIMEOUT = setTimeout(Store.keyCacheWipe, 2 * 60 * 1000);
  }
}
