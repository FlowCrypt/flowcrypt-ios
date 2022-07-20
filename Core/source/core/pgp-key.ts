/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from './buf';
import { Catch } from '../platform/catch';
import { MsgBlockParser } from './msg-block-parser';
import { PgpArmor } from './pgp-armor';
import { Store } from '../platform/store';
import { mnemonic } from './mnemonic';
import { getKeyExpirationTimeForCapabilities, strToHex } from '../platform/util';
import {
  AllowedKeyPackets, AnyKeyPacket, encryptKey, enums, generateKey, Key, KeyID,
  PacketList, PrivateKey, PublicKey, readKey, readKeys, readMessage, revokeKey,
  SecretKeyPacket, SecretSubkeyPacket, SignaturePacket, UserID
} from 'openpgp';
import { isFullyDecrypted, isFullyEncrypted } from './pgp';
import { MaybeStream, requireStreamReadToEnd } from '../platform/require';
import { Str } from './common';

const readToEnd = requireStreamReadToEnd();

export type Contact = {
  email: string;
  name: string | null;
  pubkey: string | null;
  has_pgp: 0 | 1; // eslint-disable-line @typescript-eslint/naming-convention
  searchable: string[];
  client: string | null;
  fingerprint: string | null;
  longid: string | null;
  longids: string[];
  keywords: string | null;
  pending_lookup: number; // eslint-disable-line @typescript-eslint/naming-convention
  last_use: number | null; // eslint-disable-line @typescript-eslint/naming-convention
  pubkey_last_sig: number | null; // eslint-disable-line @typescript-eslint/naming-convention
  pubkey_last_check: number | null; // eslint-disable-line @typescript-eslint/naming-convention
  expiresOn: number | null;
};

export interface PrvKeyInfo {
  private: string;
  longid: string;
  passphrase?: string;
  decrypted?: PrivateKey;  // only for internal use in this file
  parsed?: Key;     // only for internal use in this file
}

export type KeyAlgo = 'curve25519' | 'rsa2048' | 'rsa4096';

export interface KeyInfo extends PrvKeyInfo {
  public: string;
  fingerprint: string;
  primary: boolean;
  keywords: string;
}

type KeyDetails$ids = {
  shortid: string;
  longid: string;
  fingerprint: string;
  keywords: string;
};

export interface KeyDetails {
  private?: string;
  public: string;
  isFullyEncrypted: boolean | undefined;
  isFullyDecrypted: boolean | undefined;
  ids: KeyDetails$ids[];
  users: string[];
  created: number;
  lastModified: number | undefined; // date of last signature, or undefined if never had valid signature
  expiration: number | undefined; // number of millis of expiration or undefined if never expires
  revoked: boolean;
  algo: { // same as openpgp.js Key.AlgorithmInfo
    algorithm: string;
    algorithmId: number;
    bits?: number;
    curve?: string;
  };
}

export type PrvPacket = (SecretKeyPacket | SecretSubkeyPacket);

type KeyRevocationResult = {
  key: PrivateKey;
  revocationCertificate: string;
};

export class PgpKey {
  public static create = async (userIds: UserID[], variant: KeyAlgo, passphrase: string):
    Promise<{ private: string, public: string, revCert: string }> => {
    const k = await generateKey({
      userIDs: userIds, passphrase, format: 'armored',
      curve: (variant === 'curve25519' ? 'curve25519' : undefined),
      rsaBits: (variant === 'curve25519' ? undefined : (variant === 'rsa2048' ? 2048 : 4096))
    });
    return { public: k.publicKey, private: k.privateKey, revCert: k.revocationCertificate };
  };

  /**
   * used only for keys that we ourselves parsed / formatted before, eg from local storage, because no err handling
   */
  public static read = async (armoredKey: string) => { // should be renamed to readOne
    const fromCache = Store.armoredKeyCacheGet(armoredKey);
    if (fromCache) {
      return fromCache;
    }
    const key = await readKey({ armoredKey });
    if (key?.isPrivate()) {
      Store.armoredKeyCacheSet(armoredKey, key);
    }
    return key;
  };

  /**
   * Read many keys, could be armored or binary, in single armor or separately,
   * useful for importing keychains of various formats
   */
  public static readMany = async (fileData: Buf): Promise<{ keys: Key[], errs: Error[] }> => {
    const allKeys: Key[] = [];
    const allErrs: Error[] = [];
    const { blocks } = MsgBlockParser.detectBlocks(fileData.toUtfStr());
    const armoredPublicKeyBlocks = blocks.filter(block => block.type === 'publicKey' || block.type === 'privateKey');
    const pushKeysAndErrs = async (content: string | Buf, type: 'readArmored' | 'read') => {
      try {
        const keys = type === 'readArmored'
          ? await readKeys({ armoredKeys: content.toString() })
          : await readKeys({ binaryKeys: (typeof content === 'string' ? Buf.fromUtfStr(content) : content) });
        allKeys.push(...keys);
      } catch (e) {
        allErrs.push(e instanceof Error ? e : new Error(String(e)));
      }
    };
    if (armoredPublicKeyBlocks.length) {
      for (const block of blocks) {
        await pushKeysAndErrs(block.content, 'readArmored');
      }
    } else {
      await pushKeysAndErrs(fileData, 'read');
    }
    return { keys: allKeys, errs: allErrs };
  };

  public static isPacketPrivate = (packet: AllowedKeyPackets): packet is PrvPacket => {
    return packet instanceof SecretKeyPacket || packet instanceof SecretSubkeyPacket;
  };

  public static validateAllDecryptedPackets = async (key: Key): Promise<void> => {
    for (const prvPacket of key.toPacketList().filter(PgpKey.isPacketPrivate)) {
      if (prvPacket.isDecrypted()) {
        await prvPacket.validate(); // gnu-dummy never raises an exception, invalid keys raise exceptions
      }
    }
  };

  public static decrypt = async (prv: Key, passphrase: string, optionalKeyid?: KeyID,
    optionalBehaviorFlag?: 'OK-IF-ALREADY-DECRYPTED'): Promise<boolean> => {
    if (!prv.isPrivate()) {
      throw new Error("Nothing to decrypt in a public key");
    }
    const chosenPrvPackets = prv.getKeys(optionalKeyid).map(k => k.keyPacket)
      .filter(PgpKey.isPacketPrivate) as PrvPacket[];
    if (!chosenPrvPackets.length) {
      throw new Error('No private key packets selected of'
        + `${prv.getKeys().map(k => k.keyPacket).filter(PgpKey.isPacketPrivate).length} prv packets available`);
    }
    for (const prvPacket of chosenPrvPackets) {
      if (prvPacket.isDecrypted()) {
        if (optionalBehaviorFlag === 'OK-IF-ALREADY-DECRYPTED') {
          continue;
        } else {
          throw new Error("Decryption failed - key packet was already decrypted");
        }
      }
      try {
        await prvPacket.decrypt(passphrase); // throws on password mismatch
        await prvPacket.validate();
      } catch (e) {
        if (e instanceof Error && e.message.toLowerCase().includes('passphrase')) {
          return false;
        }
        throw e;
      }
    }
    return true;
  };

  public static encrypt = async (prv: Key, passphrase: string) => {
    if (!passphrase || passphrase === 'undefined' || passphrase === 'null') {
      throw new Error(`Encryption passphrase should not be empty:${typeof passphrase}:${passphrase}`);
    }
    const secretPackets = prv.getKeys().map(k => k.keyPacket).filter(PgpKey.isPacketPrivate);
    const encryptedPacketCount = secretPackets.filter(p => !p.isDecrypted()).length;
    if (!secretPackets.length) {
      throw new Error(`No private key packets in key to encrypt. Is this a private key?`);
    }
    if (encryptedPacketCount) {
      throw new Error(`Cannot encrypt a key that has ${encryptedPacketCount} of ` +
        `${secretPackets.length} private packets still encrypted`);
    }
    await encryptKey({ privateKey: (prv as PrivateKey), passphrase });
  };

  public static normalize = async (armored: string):
    Promise<{ normalized: string, keys: Key[], error?: string | undefined }> => {
    try {
      let keys: Key[] = [];
      armored = PgpArmor.normalize(armored, 'key');
      if (RegExp(PgpArmor.headers('publicKey', 're').begin).test(armored)) {
        keys = (await readKeys({ armoredKeys: armored }));
      } else if (RegExp(PgpArmor.headers('privateKey', 're').begin).test(armored)) {
        keys = (await readKeys({ armoredKeys: armored }));
      } else if (RegExp(PgpArmor.headers('encryptedMsg', 're').begin).test(armored)) {
        const msg = await readMessage({ armoredMessage: armored });
        keys = [new PublicKey(msg.packets as PacketList<AnyKeyPacket>)];
      }
      for (const k of keys) {
        for (const u of k.users) {
          await PgpKey.validateAllDecryptedPackets(k);
          u.otherCertifications = []; // prevent key bloat
        }
      }
      return { normalized: keys.map(k => k.armor()).join('\n'), keys };
    } catch (error) {
      Catch.reportErr(error);
      return { normalized: '', keys: [], error: Str.extractErrorMessage(error) };
    }
  };

  public static fingerprint = async (key: Key | string, formatting: "default" | "spaced" = 'default'):
    Promise<string | undefined> => {
    if (!key) {
      return undefined;
    } else if (key instanceof Key) {
      if (!key.keyPacket.getFingerprintBytes()) {
        return undefined;
      }
      try {
        const fp = key.keyPacket.getFingerprint().toUpperCase();
        if (formatting === 'spaced') {
          return fp.replace(/(.{4})/g, '$1 ').trim();
        }
        return fp;
      } catch (e) {
        console.error(e);
        return undefined;
      }
    } else {
      try {
        return await PgpKey.fingerprint(await PgpKey.read(key), formatting);
      } catch (e) {
        if (e instanceof Error && e.message === 'openpgp is not defined') {
          Catch.reportErr(e);
        }
        console.error(e);
        return undefined;
      }
    }
  };

  public static longid = async (keyOrFingerprintOrBytes: string | Key | undefined): Promise<string | undefined> => {
    if (!keyOrFingerprintOrBytes) {
      return undefined;
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 8) {
      return strToHex(keyOrFingerprintOrBytes).toUpperCase();
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 40) {
      return keyOrFingerprintOrBytes.substr(-16);
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 49) {
      return keyOrFingerprintOrBytes.replace(/ /g, '').substr(-16);
    }
    return await PgpKey.longid(await PgpKey.fingerprint(keyOrFingerprintOrBytes));
  };

  public static longids = async (keyIds: KeyID[]) => {
    const longids: string[] = [];
    for (const id of keyIds) {
      const longid = await PgpKey.longid(id.bytes);
      if (longid) {
        longids.push(longid);
      }
    }
    return longids;
  };

  public static usable = async (armored: string) => { // is pubkey usable for encrytion?
    const fingerprint = await PgpKey.fingerprint(armored);
    if (!fingerprint) {
      return false;
    }
    const pubkey = await readKey({ armoredKey: armored });
    if (!pubkey) {
      return false;
    }
    if (await pubkey.getEncryptionKey()) {
      return true; // good key - cannot be expired
    }
    return await PgpKey.usableButExpired(pubkey);
  };

  public static expired = async (key: Key): Promise<boolean> => {
    if (!key) {
      return false;
    }
    const exp = await key.getExpirationTime();
    if (exp === Infinity || !exp) {
      return false;
    }
    if (exp instanceof Date) {
      return Date.now() > exp.getTime();
    }
    throw new Error(`Got unexpected value for expiration: ${exp}`); // exp must be either null, Infinity or a Date
  };

  public static usableButExpired = async (key: Key): Promise<boolean> => {
    if (!key) {
      return false;
    }
    if (await key.getEncryptionKey()) {
      return false; // good key - cannot be expired
    }
    const oneSecondBeforeExpiration = await PgpKey.dateBeforeExpiration(key);
    if (typeof oneSecondBeforeExpiration === 'undefined') {
      return false; // key does not expire
    }
    // try to see if the key was usable just before expiration
    return Boolean(await key.getEncryptionKey(undefined, oneSecondBeforeExpiration));
  };

  public static dateBeforeExpiration = async (key: Key | string): Promise<Date | undefined> => {
    const openPgpKey = typeof key === 'string' ? await PgpKey.read(key) : key;
    // const expires = await openPgpKey.getExpirationTime();
    // meanhile use or backported fuinction
    const expires = await getKeyExpirationTimeForCapabilities(openPgpKey, 'encrypt');
    if (expires instanceof Date && expires.getTime() < Date.now()) { // expired
      return new Date(expires.getTime() - 1000);
    }
    return undefined;
  };

  public static parse = async (armored: string):
    Promise<{ original: string, normalized: string, keys: KeyDetails[], error?: string | undefined }> => {
    const { normalized, keys, error } = await PgpKey.normalize(armored);
    return { original: armored, normalized, keys: await Promise.all(keys.map(PgpKey.details)), error };
  };

  public static details = async (k: Key): Promise<KeyDetails> => {
    const keys = k.getKeys();
    const algoInfo = k.keyPacket.getAlgorithmInfo();
    const algo = {
      algorithm: algoInfo.algorithm,
      bits: algoInfo.bits,
      curve: algoInfo.curve,
      algorithmId: enums.publicKey[algoInfo.algorithm]
    };
    const created = k.keyPacket.created.getTime() / 1000;
    // meanwhile use our backported function
    const exp = await getKeyExpirationTimeForCapabilities(k, 'encrypt');
    const expiration = exp === Infinity || !exp ? undefined : (exp as Date).getTime() / 1000;
    const lastModified = await PgpKey.lastSig(k) / 1000;
    const ids: KeyDetails$ids[] = [];
    for (const key of keys) {
      const fingerprint = key.getFingerprint().toUpperCase();
      if (fingerprint) {
        const longid = await PgpKey.longid(fingerprint);
        if (longid) {
          const shortid = longid.substr(-8);
          ids.push({ fingerprint, longid, shortid, keywords: mnemonic(longid)! });
        }
      }
    }
    return {
      private: k.isPrivate() ? k.armor() : undefined,
      isFullyDecrypted: k.isPrivate() ? isFullyDecrypted(k) : undefined,
      isFullyEncrypted: k.isPrivate() ? isFullyEncrypted(k) : undefined,
      public: k.toPublic().armor(),
      users: k.getUserIDs(),
      ids,
      algo,
      created,
      expiration,
      lastModified,
      revoked: k.revocationSignatures.length > 0
    };
  };

  /**
   * Get latest self-signature date, in utc millis.
   * This is used to figure out how recently was key updated, and if one key is newer than other.
   */
  public static lastSig = async (key: Key): Promise<number> => {
    // "await key.getExpirationTime()" no longer works, need some alternate solution
    // discussion is in progress: https://github.com/openpgpjs/openpgpjs/discussions/1491
    const allSignatures: SignaturePacket[] = [];
    for (const user of key.users) {
      const data = { userID: user.userID, userAttribute: user.userAttribute, key };
      for (const selfCert of user.selfCertifications) {
        try {
          await selfCert.verify(key.keyPacket, enums.signature.certGeneric, data);
          allSignatures.push(selfCert);
        } catch (e) {
          console.log(`PgpKey.lastSig: Skipping self-certification signature because it is invalid: ${String(e)}`);
        }
      }
    }
    for (const subKey of key.subkeys) {
      try {
        const latestValidKeyBindingSig = await subKey.verify();
        allSignatures.push(latestValidKeyBindingSig);
      } catch (e) {
        console.log(`PgpKey.lastSig: Skipping subkey ${subKey.getKeyID().toHex()} ` +
          `because there is no valid binding signature: ${String(e)}`);
      }
    }
    if (allSignatures.length > 0) {
      return Math.max(...allSignatures.map(x => x.created ? x.created.getTime() : 0));
    }
    throw new Error('No valid signature found in key');
  };

  public static revoke = async (key: PrivateKey): Promise<KeyRevocationResult | undefined> => {
    if (! await key.isRevoked()) {
      const keypair = await revokeKey({ key, format: 'object' });
      key = keypair.privateKey;
    }
    const certificate = await key.getRevocationCertificate();
    if (!certificate) {
      return undefined;
    } else if (typeof certificate === 'string') {
      return { key, revocationCertificate: certificate };
    } else {
      return {
        key,
        revocationCertificate: await readToEnd(certificate as MaybeStream<string>)
      };
    }
  };
}
