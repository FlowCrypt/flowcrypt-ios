/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

/// <reference path="../core/types/openpgp.d.ts" />

import { str_to_hex } from './util';

let KEY_CACHE: { [longidOrArmoredKey: string]: OpenPGP.Key } = {};
let KEY_CACHE_WIPE_TIMEOUT: NodeJS.Timeout;

const keyLongid = (k: OpenPGP.Key) => str_to_hex(k.getKeyID().bytes).toUpperCase();

export class Store {

  static decryptedKeyCacheSet = (k: OpenPGP.Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[keyLongid(k)] = k;
  }

  static decryptedKeyCacheGet = (longid: string): OpenPGP.Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[longid];
  }

  static armoredKeyCacheSet = (armored: string, k: OpenPGP.Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[armored] = k;
  }

  static armoredKeyCacheGet = (armored: string): OpenPGP.Key | undefined => {
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
