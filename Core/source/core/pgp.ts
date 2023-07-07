/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { PgpKey, PrvPacket } from './pgp-key';

import { VERSION } from './const';
import { Key, KeyID, config } from 'openpgp';

config.versionString = `FlowCrypt ${VERSION} Gmail Encryption`;
config.commentString = 'Seamlessly send and receive encrypted email';
// we manually check for missing MDC and show loud warning to user (no auto-decrypt)
config.allowUnauthenticatedMessages = true;
config.allowUnauthenticatedStream = true;
// config.require_uid_self_cert = false;

const getPrvPackets = (k: Key) => {
  if (!k.isPrivate()) {
    throw new Error('Cannot check encryption status of secret keys in a Public Key');
  }
  const prvPackets = k
    .getKeys()
    .map(k => k.keyPacket)
    .filter(PgpKey.isPacketPrivate) as PrvPacket[];
  if (!prvPackets.length) {
    throw new Error('This key has no private packets. Is it a Private Key?');
  }
  const nonDummyPrvPackets = prvPackets.filter(p => !p.isDummy());
  if (!nonDummyPrvPackets.length) {
    throw new Error('This key only has a gnu-dummy private packet, with no actual secret keys.');
  }
  return nonDummyPrvPackets;
};

export const isFullyDecrypted = (key: Key): boolean => {
  return getPrvPackets(key).every(p => p.isDecrypted() === true);
};

export const isFullyEncrypted = (key: Key): boolean => {
  return getPrvPackets(key).every(p => p.isDecrypted() === false);
};

export const isPacketDecrypted = (key: Key, keyID: KeyID): boolean => {
  if (!key.isPrivate()) {
    throw new Error('Cannot check packet encryption status of secret key in a Public Key');
  }
  if (!keyID) {
    throw new Error('No KeyID provided to isPacketDecrypted');
  }
  const [k] = key.getKeys(keyID);
  if (!k) {
    throw new Error('KeyID not found in Private Key');
  }
  return k.keyPacket.isDecrypted() === true;
};
