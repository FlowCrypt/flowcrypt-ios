/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Contact } from '../core/pgp-key.js';
import { openpgp } from '../core/pgp.js';

let KEY_CACHE: { [longidOrArmoredKey: string]: OpenPGP.key.Key } = {};
let KEY_CACHE_WIPE_TIMEOUT: NodeJS.Timeout;

const keyLongid = (k: OpenPGP.key.Key) => openpgp.util.str_to_hex(k.getKeyId().bytes).toUpperCase();

export class Store {

  static dbContactGet = async (db: void, emailOrLongid: string[]): Promise<(Contact | undefined)[]> => {
    return [];
  }

  static decryptedKeyCacheSet = (k: OpenPGP.key.Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[keyLongid(k)] = k;
  }

  static decryptedKeyCacheGet = (longid: string): OpenPGP.key.Key | undefined => {
    Store.keyCacheRenewExpiry();
    return KEY_CACHE[longid];
  }

  static armoredKeyCacheSet = (armored: string, k: OpenPGP.key.Key) => {
    Store.keyCacheRenewExpiry();
    KEY_CACHE[armored] = k;
  }

  static armoredKeyCacheGet = (armored: string): OpenPGP.key.Key | undefined => {
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
