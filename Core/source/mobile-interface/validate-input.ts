/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { openpgp } from '../core/pgp';

type Obj = { [k: string]: any };

export namespace NodeRequest {
  type PrvKeyInfo = { private: string; longid: string, passphrase: string | undefined };
  type Attachment = { name: string; type: string; base64: string };
  interface composeEmailBase { text: string, to: string[], cc: string[], bcc: string[], from: string, subject: string, replyToMimeMsg: string, atts?: Attachment[] };
  export interface composeEmailPlain extends composeEmailBase { format: 'plain' };
  export interface composeEmailEncrypted extends composeEmailBase { format: 'encrypt-inline' | 'encrypt-pgpmime', pubKeys: string[] };

  export type generateKey = { passphrase: string, variant: 'rsa2048' | 'rsa4096' | 'curve25519', userIds: { name: string, email: string }[] };
  export type composeEmail = composeEmailPlain | composeEmailEncrypted;
  export type encryptMsg = { pubKeys: string[] };
  export type encryptFile = { pubKeys: string[], name: string };
  export type parseDecryptMsg = { keys: PrvKeyInfo[], msgPwd?: string, isEmail?: boolean };
  export type decryptFile = { keys: PrvKeyInfo[], msgPwd?: string };
  export type parseDateStr = { dateStr: string };
  export type zxcvbnStrengthBar = { guesses: number, purpose: 'passphrase', value: undefined } | { value: string, purpose: 'passphrase', guesses: undefined };
  export type gmailBackupSearch = { acctEmail: string };
  export type isEmailValid = { email: string };
  export type decryptKey = { armored: string, passphrases: string[] };
  export type encryptKey = { armored: string, passphrase: string };
}

export class ValidateInput {

  public static generateKey = (v: any): NodeRequest.generateKey => {
    if (isObj(v) && hasProp(v, 'userIds', 'Userid[]') && v.userIds.length && hasProp(v, 'passphrase', 'string') && ['rsa2048', 'rsa4096', 'curve25519'].includes(v.variant)) {
      return v as NodeRequest.generateKey;
    }
    throw new Error('Wrong request structure for NodeRequest.generateKey');
  }

  public static encryptMsg = (v: any): NodeRequest.encryptMsg => {
    if (isObj(v) && hasProp(v, 'pubKeys', 'string[]')) {
      return v as NodeRequest.encryptMsg;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptMsg');
  }

  public static composeEmail = (v: any): NodeRequest.composeEmail => {
    if (!(isObj(v) && hasProp(v, 'text', 'string') && hasProp(v, 'from', 'string') && hasProp(v, 'subject', 'string') && hasProp(v, 'to', 'string[]') && hasProp(v, 'cc', 'string[]') && hasProp(v, 'bcc', 'string[]'))) {
      throw new Error('Wrong request structure for NodeRequest.composeEmail, need: text,from,subject,to,cc,bcc,atts (can use empty arr for cc/bcc, and can skip atts)');
    }
    if (!hasProp(v, 'atts', 'Attachment[]?')) {
      throw new Error('Wrong atts structure for NodeRequest.composeEmail, need: {name, type, base64}');
    }
    if (hasProp(v, 'pubKeys', 'string[]') && v.pubKeys.length && (v.format === 'encrypt-inline' || v.format === 'encrypt-pgpmime')) {
      return v as NodeRequest.composeEmailEncrypted;
    }
    if (!v.pubKeys && v.format === 'plain') {
      return v as NodeRequest.composeEmailPlain;
    }
    throw new Error('Wrong choice of pubKeys and format. Either pubKeys:[..]+format:encrypt-inline OR format:plain allowed');
  }

  public static parseDecryptMsg = (v: any): NodeRequest.parseDecryptMsg => {
    if (isObj(v) && hasProp(v, 'keys', 'PrvKeyInfo[]') && hasProp(v, 'msgPwd', 'string?') && hasProp(v, 'isEmail', 'boolean?')) {
      return v as NodeRequest.parseDecryptMsg;
    }
    throw new Error('Wrong request structure for NodeRequest.parseDecryptMsg');
  }

  public static encryptFile = (v: any): NodeRequest.encryptFile => {
    if (isObj(v) && hasProp(v, 'pubKeys', 'string[]') && hasProp(v, 'name', 'string')) {
      return v as NodeRequest.encryptFile;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptFile');
  }

  public static decryptFile = (v: any): NodeRequest.decryptFile => {
    if (isObj(v) && hasProp(v, 'keys', 'PrvKeyInfo[]') && hasProp(v, 'msgPwd', 'string?')) {
      return v as NodeRequest.decryptFile;
    }
    throw new Error('Wrong request structure for NodeRequest.decryptFile');
  }

  public static parseDateStr = (v: any): NodeRequest.parseDateStr => {
    if (isObj(v) && hasProp(v, 'dateStr', 'string')) {
      return v as NodeRequest.parseDateStr;
    }
    throw new Error('Wrong request structure for NodeRequest.dateStrParse');
  }

  public static zxcvbnStrengthBar = (v: any): NodeRequest.zxcvbnStrengthBar => {
    if (isObj(v) && hasProp(v, 'guesses', 'number') && hasProp(v, 'purpose', 'string') && v.purpose === 'passphrase') {
      return v as NodeRequest.zxcvbnStrengthBar;
    }
    if (isObj(v) && hasProp(v, 'value', 'string') && hasProp(v, 'purpose', 'string') && v.purpose === 'passphrase') {
      return v as NodeRequest.zxcvbnStrengthBar;
    }
    throw new Error('Wrong request structure for NodeRequest.zxcvbnStrengthBar');
  }

  public static gmailBackupSearch = (v: any): NodeRequest.gmailBackupSearch => {
    if (isObj(v) && hasProp(v, 'acctEmail', 'string')) {
      return v as NodeRequest.gmailBackupSearch;
    }
    throw new Error('Wrong request structure for NodeRequest.gmailBackupSearchQuery');
  }

  public static isEmailValid = (v: any): NodeRequest.isEmailValid => {
    if (isObj(v) && hasProp(v, 'email', 'string')) {
      return v as NodeRequest.isEmailValid;
    }
    throw new Error('Wrong request structure for NodeRequest.isEmailValid');
  }

  public static decryptKey = (v: any): NodeRequest.decryptKey => {
    if (isObj(v) && hasProp(v, 'armored', 'string') && hasProp(v, 'passphrases', 'string[]')) {
      return v as NodeRequest.decryptKey;
    }
    throw new Error('Wrong request structure for NodeRequest.decryptKey');
  }

  public static encryptKey = (v: any): NodeRequest.encryptKey => {
    if (isObj(v) && hasProp(v, 'armored', 'string') && hasProp(v, 'passphrase', 'string')) {
      return v as NodeRequest.encryptKey;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptKey');
  }

}

const isObj = (v: any): v is Obj => {
  return v && typeof v === 'object';
}

const hasProp = (v: Obj, name: string, type: 'string[]' | 'object' | 'string' | 'number' | 'string?' | 'boolean?' | 'PrvKeyInfo[]' | 'Userid[]' | 'Attachment[]?'): boolean => {
  if (!isObj(v)) {
    return false;
  }
  const value = v[name];
  if (type === 'number' || type === 'string') {
    return typeof value === type;
  }
  if (type === 'boolean?') {
    return typeof value === 'boolean' || typeof value === 'undefined';
  }
  if (type === 'string?') {
    if (value === null) {
      v[name] = undefined;
      return true;
    }
    return typeof value === 'string' || typeof value === 'undefined';
  }
  if (type === 'Attachment[]?') {
    return typeof value === 'undefined' || (Array.isArray(value) && value.filter((x: any) => hasProp(x, 'name', 'string') && hasProp(x, 'type', 'string') && hasProp(x, 'base64', 'string')).length === value.length);
  }
  if (type === 'string[]') {
    return Array.isArray(value) && value.filter((x: any) => typeof x === 'string').length === value.length;
  }
  if (type === 'PrvKeyInfo[]') {
    return Array.isArray(value) && value.filter((ki: any) => hasProp(ki, 'private', 'string') && hasProp(ki, 'longid', 'string') && hasProp(ki, 'passphrase', 'string?')).length === value.length;
  }
  if (type === 'Userid[]') {
    return Array.isArray(value) && value.filter((ui: any) => hasProp(ui, 'name', 'string') && hasProp(ui, 'email', 'string')).length === value.length;
  }
  if (type === 'object') {
    return isObj(value);
  }
  return false;
}

export const readArmoredKeyOrThrow = async (armored: string) => {
  const { keys: [key], err } = await openpgp.key.readArmored(armored);
  if (err && err.length && err[0] instanceof Error) {
    throw err[0];
  }
  if (!key) {
    throw new Error('No key found');
  }
  return key;
}