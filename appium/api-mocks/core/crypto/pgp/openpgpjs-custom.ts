/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { PrvPacket } from '../key.js';

import { VERSION } from '../../const.js';
import { requireOpenpgp } from '../../../platform/require.js';
import { OpenPGPKey } from './openpgp-key.js';

export const opgp = requireOpenpgp();

if (typeof opgp !== 'undefined') { // in certain environments, eg pgp_block.htm, openpgp is not included
  opgp.config.versionstring = `FlowCrypt Email Encryption ${VERSION}`;
  opgp.config.commentstring = 'Seamlessly send and receive encrypted email';
  opgp.config.ignore_mdc_error = true; // we manually check for missing MDC and show loud warning to user (no auto-decrypt)
  opgp.config.allow_insecure_decryption_with_signing_keys = false; // may get later over-written using OrgRules for some clients
  // openpgp.config.require_uid_self_cert = false;
  const getPrvPackets = (k: OpenPGP.key.Key) => {
    if (!k.isPrivate()) {
      throw new Error("Cannot check encryption status of secret keys in a Public Key");
    }
    const prvPackets = k.getKeys().map(k => k.keyPacket).filter(OpenPGPKey.isPacketPrivate) as PrvPacket[];
    if (!prvPackets.length) {
      throw new Error("This key has no private packets. Is it a Private Key?");
    }
    // only encrypted keys have s2k (decrypted keys don't needed, already decrypted)
    // if s2k is present and it indicates it's a dummy key, filter it out
    // if s2k is not present, it's a decrypted real key (not dummy)
    const nonDummyPrvPackets = prvPackets.filter(p => !p.s2k || p.s2k.type !== 'gnu-dummy');
    if (!nonDummyPrvPackets.length) {
      throw new Error("This key only has a gnu-dummy private packet, with no actual secret keys.");
    }
    return nonDummyPrvPackets;
  };
  opgp.key.Key.prototype.isFullyDecrypted = function () {
    return getPrvPackets(this).every(p => p.isDecrypted() === true);
  };
  opgp.key.Key.prototype.isFullyEncrypted = function () {
    return getPrvPackets(this).every(p => p.isDecrypted() === false);
  };
  opgp.key.Key.prototype.isPacketDecrypted = function (keyId: OpenPGP.Keyid) {
    if (!this.isPrivate()) {
      throw new Error("Cannot check packet encryption status of secret key in a Public Key");
    }
    if (!keyId) {
      throw new Error("No Keyid provided to isPacketDecrypted");
    }
    const [key] = this.getKeys(keyId);
    if (!key) {
      throw new Error("Keyid not found in Private Key");
    }
    return key.keyPacket.isDecrypted() === true;
  };
}
