/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { PgpKey, PrvPacket } from './pgp-key';

import { VERSION } from './const';
import { Key, KeyID, config } from './types/openpgp';

config.versionString = `FlowCrypt ${VERSION} Gmail Encryption`;
config.commentString = 'Seamlessly send and receive encrypted email';
// we manually check for missing MDC and show loud warning to user (no auto-decrypt)
config.allowUnauthenticatedMessages = true;
config.allowUnauthenticatedStream = true;
// openpgp.config.require_uid_self_cert = false;
const getPrvPackets = (k: Key) => {
  if (!k.isPrivate()) {
    throw new Error("Cannot check encryption status of secret keys in a Public Key");
  }
  const prvPackets = k.getKeys().map(k => k.keyPacket).filter(PgpKey.isPacketPrivate) as PrvPacket[];
  if (!prvPackets.length) {
    throw new Error("This key has no private packets. Is it a Private Key?");
  }
  // only encrypted keys have s2k (decrypted keys don't needed, already decrypted)
  // if s2k is present and it indicates it's a dummy key, filter it out
  // if s2k is not present, it's a decrypted real key (not dummy)
  // openpgp.js v5 provides isDummy() instead.
  const nonDummyPrvPackets = prvPackets.filter(p => !p.isDummy());
  if (!nonDummyPrvPackets.length) {
    throw new Error("This key only has a gnu-dummy private packet, with no actual secret keys.");
  }
  return nonDummyPrvPackets;
};

Key.prototype.isFullyDecrypted = function () {
  return getPrvPackets(this).every(p => p.isDecrypted() === true);
};

Key.prototype.isFullyEncrypted = function () {
  return getPrvPackets(this).every(p => p.isDecrypted() === false);
};

Key.prototype.isPacketDecrypted = function (keyID: KeyID) {
  if (!this.isPrivate()) {
    throw new Error("Cannot check packet encryption status of secret key in a Public Key");
  }
  if (!keyID) {
    throw new Error("No KeyID provided to isPacketDecrypted");
  }
  const [key] = this.getKeys(keyID);
  if (!key) {
    throw new Error("KeyID not found in Private Key");
  }
  return key.keyPacket.isDecrypted() === true;
};
