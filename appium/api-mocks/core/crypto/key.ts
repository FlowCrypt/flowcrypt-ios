/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buf } from '../buf.js';
import { Catch } from '../../platform/catch.js';
import { MsgBlockParser } from '../msg-block-parser.js';
import { PgpArmor } from './pgp/pgp-armor.js';
import { opgp } from './pgp/openpgpjs-custom.js';
import { OpenPGPKey } from './pgp/openpgp-key.js';
import { SmimeKey } from './smime/smime-key.js';
import { MsgBlock } from '../msg-block.js';
import { PubkeyInfo } from '../../platform/store/contact-store.js';

/**
 * This is a common Key interface for both OpenPGP and X.509 keys.
 *
 * Since Key objects are frequently JSON serialized (e.g. via message passing)
 * all dates are expressed as number of milliseconds since Unix Epoch.
 * This is what `Date.now()` returns and `new Date(x)` accepts.
 */
export interface Key extends KeyIdentity {
  allIds: string[]; // a list of fingerprints, including those for subkeys
  created: number;
  revoked: boolean;
  lastModified: number | undefined; // date of last signature, or undefined if never had valid signature
  expiration: number | undefined; // number of millis of expiration or undefined if never expires
  usableForEncryption: boolean;
  usableForSigning: boolean;
  usableForEncryptionButExpired: boolean;
  usableForSigningButExpired: boolean;
  missingPrivateKeyForSigning: boolean;
  missingPrivateKeyForDecryption: boolean;
  emails: string[];
  identities: string[];
  fullyDecrypted: boolean;
  fullyEncrypted: boolean;
  isPublic: boolean; // isPublic and isPrivate are mutually exclusive
  isPrivate: boolean; // only one should be set to true
  algo: {
    algorithm: string,
    curve?: string,
    bits?: number,
    algorithmId: number
  };
  issuerAndSerialNumber?: string | undefined; // DER-encoded IssuerAndSerialNumber of X.509 Certificate as raw string
}

export type PubkeyResult = { pubkey: Key, email: string, isMine: boolean };

export type Contact = {
  email: string;
  name: string | null;
  pubkey: Key | undefined;
  hasPgp: 0 | 1;
  fingerprint: string | null;
  lastUse: number | null;
  pubkeyLastCheck: number | null;
  expiresOn: number | null;
  revoked: boolean;
};

export interface KeyInfo {
  private: string;
  public: string; // this cannot be Pubkey has it's being passed to localstorage
  longid: string;
  fingerprints: string[];
  emails?: string[]; // todo - used to be missing - but migration was supposed to add it? setting back to optional for now
}

export interface KeyIdentity {
  id: string, // a fingerprint of the primary key in OpenPGP, and similarly a fingerprint of the actual cryptographic key (eg RSA fingerprint) in S/MIME
  type: 'openpgp' | 'x509'
}

export interface TypedKeyInfo extends KeyInfo, KeyIdentity {
}

export interface ExtendedKeyInfo extends TypedKeyInfo {
  passphrase?: string;
}

export type KeyAlgo = 'curve25519' | 'rsa2048' | 'rsa3072' | 'rsa4096';

export type PrvPacket = (OpenPGP.packet.SecretKey | OpenPGP.packet.SecretSubkey);

export class UnexpectedKeyTypeError extends Error { }

export class KeyUtil {

  public static identityEquals = (keyIdentity1: KeyIdentity, keyIdentity2: KeyIdentity) => {
    return keyIdentity1.id === keyIdentity2.id && keyIdentity1.type === keyIdentity2.type;
  }

  public static filterKeys<T extends KeyIdentity>(kis: T[], ids: KeyIdentity[]): T[] {
    return kis.filter(ki => ids.some(i => KeyUtil.identityEquals(i, ki)));
  }

  public static filterKeysByTypeAndSenderEmail = (keys: TypedKeyInfo[], email: string, type: 'openpgp' | 'x509' | undefined): TypedKeyInfo[] => {
    let foundKeys: TypedKeyInfo[] = [];
    if (type) {
      foundKeys = keys.filter(key => key.emails?.includes(email.toLowerCase()) && key.type === type);
      if (!foundKeys.length) {
        foundKeys = keys.filter(key => key.type === type);
      }
    } else {
      foundKeys = keys.filter(key => key.emails?.includes(email.toLowerCase()));
      if (!foundKeys.length) {
        foundKeys = [...keys];
      }
    }
    return foundKeys;
  }

  public static groupByType<T extends { type: string }>(items: T[]): { [type: string]: T[] } {
    return items.reduce((rv: { [type: string]: T[] }, x: T) => {
      (rv[x.type] = rv[x.type] || []).push(x);
      return rv;
    }, {});
  }

  public static isWithoutSelfCertifications = async (key: Key) => {
    // all non-OpenPGP keys are automatically considered to be not
    // "without self certifications"
    if (key.type !== 'openpgp') {
      return false;
    }
    return await OpenPGPKey.isWithoutSelfCertifications(key);
  }

  /**
   * Read many keys, could be armored or binary, in single armor or separately, useful for importing keychains of various formats
   */
  public static readMany = async (fileData: Buf): Promise<{ keys: Key[], errs: Error[] }> => {
    const allKeys: Key[] = [];
    const allErrs: Error[] = [];
    const { blocks } = MsgBlockParser.detectBlocks(fileData.toUtfStr('ignore'));
    const isImportable = (block: MsgBlock) => block.type === 'publicKey' || block.type === 'privateKey' || block.type === 'certificate';
    const armoredPublicKeyBlocks = blocks.filter(isImportable);
    const pushKeysAndErrs = async (content: string | Buf, isArmored: boolean) => {
      try {
        if (isArmored) {
          allKeys.push(...await KeyUtil.parseMany(content.toString()));
        } else {
          const buf = typeof content === 'string' ? Buf.fromUtfStr(content) : content;
          const { keys, err } = await KeyUtil.readBinary(buf);
          allKeys.push(...keys);
          allErrs.push(...err);
        }
      } catch (e) {
        allErrs.push(e instanceof Error ? e : new Error(String(e)));
      }
    };
    if (armoredPublicKeyBlocks.length) {
      for (const block of blocks) {
        await pushKeysAndErrs(block.content, true);
      }
    } else {
      await pushKeysAndErrs(fileData, false);
    }
    return { keys: allKeys, errs: allErrs };
  }

  public static parse = async (text: string): Promise<Key> => {
    const keys = await KeyUtil.parseMany(text);
    const keysLength = keys.length;
    if (keysLength > 1) {
      throw new Error(`Found ${keysLength} keys, expected one`);
    }
    return keys[0];
  }

  public static parseMany = async (text: string): Promise<Key[]> => {
    const keyType = KeyUtil.getKeyType(text);
    if (keyType === 'openpgp') {
      return await OpenPGPKey.parseMany(text);
    } else if (keyType === 'x509') {
      // TODO: No support for parsing multiple S/MIME keys for now
      return [SmimeKey.parse(text)];
    }
    throw new UnexpectedKeyTypeError(`Key type is ${keyType}, expecting OpenPGP or x509 S/MIME`);
  }

  public static readBinary = async (key: Uint8Array, passPhrase?: string | undefined): Promise<{ keys: Key[], err: Error[] }> => {
    const allKeys: Key[] = [], allErr: Error[] = [];
    try {
      const { keys, err } = await opgp.key.read(key);
      if (keys.length > 0) {
        for (const key of keys) {
          // we should decrypt them all here to have consistent behavior between pkcs12 files and PGP
          // pkcs12 files must be decrypted during parsing
          // then rename this method to parseDecryptBinary
          const parsed = await OpenPGPKey.convertExternalLibraryObjToKey(key);
          // if (await KeyUtil.decrypt(parsed, passPhrase, undefined, 'OK-IF-ALREADY-DECRYPTED')) {
          allKeys.push(parsed);
          // } else {
          //   allErr.push(new Error(`Wrong pass phrase for OpenPGP key ${parsed.id} (${parsed.emails[0]})`));
          // }
        }
      }
      if (err) {
        allErr.push(...err);
      }
    } catch (e) {
      allErr.push(e as Error);
    }
    if (!allKeys.length) {
      try {
        allKeys.push(SmimeKey.parseDecryptBinary(key, passPhrase ?? ''));
        return { keys: allKeys, err: [] };
      } catch (e) {
        allErr.push(e as Error);
      }
    }
    return { keys: allKeys, err: allErr };
  }

  public static parseBinary = async (key: Uint8Array, passPhrase?: string | undefined): Promise<Key[]> => {
    const { keys, err } = await KeyUtil.readBinary(key, passPhrase);
    if (keys.length > 0) {
      return keys;
    }
    throw new Error(err.length ? err.map((e, i) => (i + 1) + '. ' + e.message).join('\n') : 'Should not happen: no keys and no errors.');
  }

  public static armor = (pubkey: Key): string => {
    const armored = (pubkey as unknown as { rawArmored: string }).rawArmored;
    if (!armored) {
      throw new Error('The Key object has no rawArmored field.');
    }
    return armored;
  }

  public static diagnose = async (key: Key, passphrase: string): Promise<Map<string, string>> => {
    let result = new Map<string, string>();
    result.set(`Key type`, key.type);
    if (key.type === 'openpgp') {
      const opgpresult = await OpenPGPKey.diagnose(key, passphrase);
      result = new Map<string, string>([...result, ...opgpresult]);
    }
    result.set(`expiration`, KeyUtil.formatResult(key.expiration));
    result.set(`internal dateBeforeExpiration`, await KeyUtil.formatResultAsync(async () => KeyUtil.dateBeforeExpirationIfAlreadyExpired(key)));
    result.set(`internal usableForEncryptionButExpired`, KeyUtil.formatResult(key.usableForEncryptionButExpired));
    result.set(`internal usableForSigningButExpired`, KeyUtil.formatResult(key.usableForSigningButExpired));
    return result;
  }

  public static formatResultAsync = async (f: () => Promise<unknown>): Promise<string> => {
    try {
      return KeyUtil.formatResult(await f());
    } catch (e) {
      return `[${String(e)}]`;
    }
  }

  public static formatResult = (value: unknown): string => {
    return `[-] ${String(value)}`;
  }

  public static asPublicKey = async (key: Key): Promise<Key> => {
    if (key.type === 'openpgp') {
      return await OpenPGPKey.asPublicKey(key);
    } else if (key.type === 'x509') {
      return SmimeKey.asPublicKey(key);
    }
    throw new UnexpectedKeyTypeError(`Key type is ${key.type}, expecting OpenPGP or x509 S/MIME`);
  }

  public static expired = (key: Key): boolean => {
    const exp = key.expiration;
    if (!exp) {
      return false;
    }
    return Date.now() > exp;
  }

  public static dateBeforeExpirationIfAlreadyExpired = (key: Key): Date | undefined => {
    const expiration = key.expiration;
    return expiration && KeyUtil.expired(key) ? new Date(expiration - 1000) : undefined;
  }

  // todo - this should be made to tolerate smime keys
  public static normalize = async (armored: string): Promise<{ normalized: string, keys: OpenPGP.key.Key[] }> => {
    try {
      let keys: OpenPGP.key.Key[] = [];
      armored = PgpArmor.normalize(armored, 'key');
      if (RegExp(PgpArmor.headers('publicKey', 're').begin).test(armored)) {
        keys = (await opgp.key.readArmored(armored)).keys;
      } else if (RegExp(PgpArmor.headers('privateKey', 're').begin).test(armored)) {
        keys = (await opgp.key.readArmored(armored)).keys;
      } else if (RegExp(PgpArmor.headers('encryptedMsg', 're').begin).test(armored)) {
        keys = [new opgp.key.Key((await opgp.message.readArmored(armored)).packets)];
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

  public static checkPassPhrase = async (pkey: string, passphrase: string): Promise<boolean> => {
    // decrypt will change the key in place so it's important to parse the key here
    // because passing an object from the caller could have unexpected consequences
    const key = await KeyUtil.parse(pkey);
    return await KeyUtil.decrypt(key, passphrase);
  }

  public static getKeyType = (pubkey: string): 'openpgp' | 'x509' | 'unknown' => {
    if (pubkey.includes(PgpArmor.headers('certificate').begin)) {
      return 'x509';
    } else if (pubkey.startsWith(PgpArmor.headers('pkcs12').begin)) {
      return 'x509';
    } else if (pubkey.startsWith(PgpArmor.headers('publicKey').begin)) {
      return 'openpgp';
    } else if (pubkey.startsWith(PgpArmor.headers('privateKey').begin)) {
      return 'openpgp';
    } else {
      return 'unknown';
    }
  }

  public static decrypt = async (key: Key, passphrase: string, optionalKeyid?: OpenPGP.Keyid, optionalBehaviorFlag?: 'OK-IF-ALREADY-DECRYPTED'): Promise<boolean> => {
    if (key.type === 'openpgp') {
      return await OpenPGPKey.decryptKey(key, passphrase, optionalKeyid, optionalBehaviorFlag);
    } else if (key.type === 'x509') {
      return await SmimeKey.decryptKey(key, passphrase, optionalBehaviorFlag);
    } else {
      throw new Error(`KeyUtil.decrypt does not support key type ${key.type}`);
    }
  }

  public static encrypt = async (key: Key, passphrase: string) => {
    if (key.type === 'openpgp') {
      return await OpenPGPKey.encryptKey(key, passphrase);
    } else if (key.type === 'x509') {
      return await SmimeKey.encryptKey(key, passphrase);
    } else {
      throw new Error(`KeyUtil.encrypt does not support key type ${key.type}`);
    }
  }

  public static reformatKey = async (privateKey: Key, passphrase: string, userIds: { email: string | undefined; name: string }[], expireSeconds: number) => {
    if (privateKey.type === 'openpgp') {
      return await OpenPGPKey.reformatKey(privateKey, passphrase, userIds, expireSeconds);
    } else {
      throw new Error(`KeyUtil.reformatKey does not support key type ${privateKey.type}`);
    }
  }

  public static revoke = async (key: Key): Promise<string | undefined> => {
    if (key.type === 'openpgp') {
      return await OpenPGPKey.revoke(key);
    } else {
      throw new Error(`KeyUtil.revoke does not support key type ${key.type}`);
    }
  }

  public static keyInfoObj = async (prv: Key): Promise<KeyInfo> => {
    if (!prv.isPrivate) {
      throw new Error('Key passed into KeyUtil.keyInfoObj must be a Private Key');
    }
    const pubkey = await KeyUtil.asPublicKey(prv);
    return {
      private: KeyUtil.armor(prv),
      public: KeyUtil.armor(pubkey),
      longid: KeyUtil.getPrimaryLongid(pubkey),
      emails: prv.emails,
      fingerprints: prv.allIds,
    };
  }

  public static typedKeyInfoObj = async (prv: Key): Promise<TypedKeyInfo> => {
    return { ...await KeyUtil.keyInfoObj(prv), id: prv.id, type: prv.type };
  }

  public static getPubkeyLongids = (pubkey: Key): string[] => {
    if (pubkey.type !== 'x509') {
      return pubkey.allIds.map(id => OpenPGPKey.fingerprintToLongid(id));
    }
    return [KeyUtil.getPrimaryLongid(pubkey)];
  }

  public static getPrimaryLongid = (pubkey: Key): string => {
    if (pubkey.type !== 'x509') {
      return OpenPGPKey.fingerprintToLongid(pubkey.id);
    }
    return SmimeKey.getKeyLongid(pubkey);
  }

  public static getKeyInfoLongids = (ki: ExtendedKeyInfo): string[] => {
    if (ki.type !== 'x509') {
      return ki.fingerprints.map(fp => OpenPGPKey.fingerprintToLongid(fp));
    }
    return [ki.longid];
  }

  public static usableAllowingExpired = (pubinfo: PubkeyInfo) => {
    return !pubinfo.revoked && (pubinfo.pubkey.usableForEncryption || pubinfo.pubkey.usableForEncryptionButExpired);
  }
}
