/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from './buf';
import { Catch } from '../platform/catch';
import { MsgBlockParser } from './msg-block-parser';
import { PgpArmor } from './pgp-armor';
import { Store } from '../platform/store';
import { mnemonic } from './mnemonic';
import { openpgp } from './pgp';
import { PrivateKey, SecretKeyPacket, SecretSubkeyPacket } from 'openpgp';

export type Contact = {
  email: string;
  name: string | null;
  pubkey: string | null;
  has_pgp: 0 | 1;
  searchable: string[];
  client: string | null;
  fingerprint: string | null;
  longid: string | null;
  longids: string[];
  keywords: string | null;
  pending_lookup: number;
  last_use: number | null;
  pubkey_last_sig: number | null;
  pubkey_last_check: number | null;
  expiresOn: number | null;
};

export interface PrvKeyInfo {
  private: string;
  longid: string;
  passphrase?: string;
  decrypted?: OpenPGP.Key;  // only for internal use in this file
  parsed?: OpenPGP.Key;     // only for internal use in this file
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
  algo: { // same as OpenPGP.key.AlgorithmInfo
    algorithm: string;
    algorithmId: number;
    bits?: number;
    curve?: string;
  };
}
export type PrvPacket = (OpenPGP.SecretKeyPacket | OpenPGP.SecretSubkeyPacket);

export class PgpKey {
  public static create = async (userIds: OpenPGP.UserID[], variant: KeyAlgo, passphrase: string):
    Promise<{ private: string, public: string, revCert: string }> => {
    // With openpgp.js v5 Separate declaration of variable of type OpenPGP.KeyOptions
    // leads to error when calling generate().
    // I don't know how to overcome this, so just passing "inline" object, which works.
    const k = await openpgp.generateKey({
      userIDs: userIds, passphrase: passphrase, format: 'armored',
      curve: (variant === 'curve25519' ? 'curve25519' : undefined),
      rsaBits: (variant === 'curve25519' ? undefined : (variant === 'rsa2048' ? 2048 : 4096))
    });
    return { public: k.publicKey, private: k.privateKey, revCert: k.revocationCertificate };
  }

  /**
   * used only for keys that we ourselves parsed / formatted before, eg from local storage, because no err handling
   */
  public static read = async (armoredKey: string) => { // should be renamed to readOne
    const fromCache = Store.armoredKeyCacheGet(armoredKey);
    if (fromCache) {
      return fromCache;
    }
    const key = await openpgp.readKey({armoredKey: armoredKey});
    if (key?.isPrivate()) {
      Store.armoredKeyCacheSet(armoredKey, key);
    }
    return key;
  }

  /**
   * Read many keys, could be armored or binary, in single armor or separately,
   * useful for importing keychains of various formats
   */
  public static readMany = async (fileData: Buf): Promise<{ keys: OpenPGP.Key[], errs: Error[] }> => {
    const allKeys: OpenPGP.Key[] = [];
    const allErrs: Error[] = [];
    const { blocks } = MsgBlockParser.detectBlocks(fileData.toUtfStr());
    const armoredPublicKeyBlocks = blocks.filter(block => block.type === 'publicKey' || block.type === 'privateKey');
    const pushKeysAndErrs = async (content: string | Buf, type: 'readArmored' | 'read') => {
      try {
        const keys = type === 'readArmored'
          ? await openpgp.readKeys({armoredKeys: content.toString()})
          : await openpgp.readKeys({binaryKeys: (typeof content === 'string' ? Buf.fromUtfStr(content) : content)});
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
  }

  public static isPacketPrivate = (p: OpenPGP.AnyKeyPacket): p is PrvPacket => {
    return p instanceof SecretKeyPacket || p instanceof SecretSubkeyPacket;
  }

  public static decrypt = async (prv: OpenPGP.Key, passphrase: string, optionalKeyid?: OpenPGP.KeyID, optionalBehaviorFlag?: 'OK-IF-ALREADY-DECRYPTED'): Promise<boolean> => {
    if (!prv.isPrivate()) {
      throw new Error("Nothing to decrypt in a public key");
    }
    const chosenPrvPackets = prv.getKeys(optionalKeyid).map(k => k.keyPacket).filter(PgpKey.isPacketPrivate) as PrvPacket[];
    if (!chosenPrvPackets.length) {
      throw new Error(`No private key packets selected of ${prv.getKeys().map(k => k.keyPacket).filter(PgpKey.isPacketPrivate).length} prv packets available`);
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
      } catch (e) {
        if (e instanceof Error && e.message.toLowerCase().includes('passphrase')) {
          return false;
        }
        throw e;
      }
    }
    return true;
  }

  public static encrypt = async (prv: OpenPGP.Key, passphrase: string) => {
    if (!passphrase || passphrase === 'undefined' || passphrase === 'null') {
      throw new Error(`Encryption passphrase should not be empty:${typeof passphrase}:${passphrase}`);
    }
    const secretPackets = prv.getKeys().map(k => k.keyPacket).filter(PgpKey.isPacketPrivate);
    const encryptedPacketCount = secretPackets.filter(p => !p.isDecrypted()).length;
    if (!secretPackets.length) {
      throw new Error(`No private key packets in key to encrypt. Is this a private key?`);
    }
    if (encryptedPacketCount) {
      throw new Error(`Cannot encrypt a key that has ${encryptedPacketCount} of ${secretPackets.length} private packets still encrypted`);
    }
    await prv.encrypt(passphrase);
  }

  public static normalize = async (armored: string): Promise<{ normalized: string, keys: OpenPGP.Key[] }> => {
    try {
      let keys: OpenPGP.Key[] = [];
      armored = PgpArmor.normalize(armored, 'key');
      if (RegExp(PgpArmor.headers('publicKey', 're').begin).test(armored)) {
        keys = (await openpgp.readArmored(armored)).keys;
      } else if (RegExp(PgpArmor.headers('privateKey', 're').begin).test(armored)) {
        keys = (await openpgp.readArmored(armored)).keys;
      } else if (RegExp(PgpArmor.headers('encryptedMsg', 're').begin).test(armored)) {
        keys = [new OpenPGP.Key((await openpgp.message.readArmored(armored)).packets)];
      }
      for (const k of keys) {
        for (const u of k.users) {
          u.otherCertifications = []; // prevent key bloat
        }
      }
      return { normalized: keys.map(k => k.armor()).join('\n'), keys };
    } catch (error) {
      Catch.reportErr(error);
      return { normalized: '', keys: [] };
    }
  }

  public static fingerprint = async (key: OpenPGP.Key | string, formatting: "default" | "spaced" = 'default'): Promise<string | undefined> => {
    if (!key) {
      return undefined;
    } else if (key instanceof OpenPGP.Key) {
      if (!key.primaryKey.getFingerprintBytes()) {
        return undefined;
      }
      try {
        const fp = key.primaryKey.getFingerprint().toUpperCase();
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
  }

  public static longid = async (keyOrFingerprintOrBytes: string | OpenPGP.Key | undefined): Promise<string | undefined> => {
    if (!keyOrFingerprintOrBytes) {
      return undefined;
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 8) {
      return openpgp.util.str_to_hex(keyOrFingerprintOrBytes).toUpperCase();
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 40) {
      return keyOrFingerprintOrBytes.substr(-16);
    } else if (typeof keyOrFingerprintOrBytes === 'string' && keyOrFingerprintOrBytes.length === 49) {
      return keyOrFingerprintOrBytes.replace(/ /g, '').substr(-16);
    }
    return await PgpKey.longid(await PgpKey.fingerprint(keyOrFingerprintOrBytes));
  }

  public static longids = async (keyIds: OpenPGP.KeyID[]) => {
    const longids: string[] = [];
    for (const id of keyIds) {
      const longid = await PgpKey.longid(id.bytes);
      if (longid) {
        longids.push(longid);
      }
    }
    return longids;
  }

  public static usable = async (armored: string) => { // is pubkey usable for encrytion?
    if (!PgpKey.fingerprint(armored)) {
      return false;
    }
    const { keys: [pubkey] } = await openpgp.readArmored(armored);
    if (!pubkey) {
      return false;
    }
    if (await pubkey.getEncryptionKey()) {
      return true; // good key - cannot be expired
    }
    return await PgpKey.usableButExpired(pubkey);
  }

  public static expired = async (key: OpenPGP.Key): Promise<boolean> => {
    if (!key) {
      return false;
    }
    const exp = await key.getExpirationTime('encrypt');
    if (exp === Infinity || !exp) {
      return false;
    }
    if (exp instanceof Date) {
      return Date.now() > exp.getTime();
    }
    throw new Error(`Got unexpected value for expiration: ${exp}`); // exp must be either null, Infinity or a Date
  }

  public static usableButExpired = async (key: OpenPGP.Key): Promise<boolean> => {
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
  }

  public static dateBeforeExpiration = async (key: OpenPGP.Key | string): Promise<Date | undefined> => {
    const openPgpKey = typeof key === 'string' ? await PgpKey.read(key) : key;
    const expires = await openPgpKey.getExpirationTime('encrypt');
    if (expires instanceof Date && expires.getTime() < Date.now()) { // expired
      return new Date(expires.getTime() - 1000);
    }
    return undefined;
  }

  public static parse = async (armored: string): Promise<{ original: string, normalized: string, keys: KeyDetails[] }> => {
    const { normalized, keys } = await PgpKey.normalize(armored);
    return { original: armored, normalized, keys: await Promise.all(keys.map(PgpKey.details)) };
  }

  public static details = async (k: OpenPGP.Key): Promise<KeyDetails> => {
    const keys = k.getKeys();
    const algoInfo = k.primaryKey.getAlgorithmInfo();
    const algo = { algorithm: algoInfo.algorithm, bits: algoInfo.bits, curve: (algoInfo as any).curve, algorithmId: openpgp.enums.publicKey[algoInfo.algorithm] };
    const created = k.primaryKey.created.getTime() / 1000;
    const exp = await k.getExpirationTime('encrypt');
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
      isFullyDecrypted: k.isPrivate() ? k.isFullyDecrypted() : undefined,
      isFullyEncrypted: k.isPrivate() ? k.isFullyEncrypted() : undefined,
      public: k.toPublic().armor(),
      users: k.getUserIds(),
      ids,
      algo,
      created,
      expiration,
      lastModified,
      revoked: k.revocationSignatures.length > 0
    };
  }

  /**
   * Get latest self-signature date, in utc millis.
   * This is used to figure out how recently was key updated, and if one key is newer than other.
   */
  public static lastSig = async (key: OpenPGP.Key): Promise<number> => {
    await key.getExpirationTime(); // will force all sigs to be verified
    const allSignatures: OpenPGP.packet.Signature[] = [];
    for (const user of key.users) {
      allSignatures.push(...user.selfCertifications);
    }
    for (const subKey of key.subKeys) {
      allSignatures.push(...subKey.bindingSignatures);
    }
    allSignatures.sort((a, b) => b.created.getTime() - a.created.getTime());
    const newestSig = allSignatures.find(sig => sig.verified === true);
    if (newestSig) {
      return newestSig.created.getTime();
    }
    throw new Error('No valid signature found in key');
  }

  public static revoke = async (key: OpenPGP.Key): Promise<string | undefined> => {
    if (! await key.isRevoked()) {
      key = await key.revoke({});
    }
    const certificate = await key.getRevocationCertificate();
    if (!certificate || typeof certificate === 'string') {
      return certificate || undefined;
    } else {
      return await openpgp.stream.readToEnd(certificate);
    }
  }
}
