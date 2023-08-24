/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { readKey } from 'openpgp';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Obj = { [k: string]: any };

export namespace NodeRequest {
  type PrvKeyInfo = { private: string; longid: string; passphrase: string | undefined };
  type Attachment = { id: string; msgId: string; type?: string; name: string; length?: number };
  type ComposeAttachment = { name: string; type: string; base64: string };

  interface ComposeEmailBase {
    text: string;
    html?: string;
    to: string[];
    cc: string[];
    bcc: string[];
    from: string;
    subject: string;
    replyToMsgId?: string;
    inReplyTo?: string;
    atts?: ComposeAttachment[];
  }

  export interface ComposeEmailPlain extends ComposeEmailBase {
    format: 'plain';
  }

  export interface ComposeEmailEncrypted extends ComposeEmailBase {
    format: 'encryptInline' | 'encryptPgpmime';
    pubKeys: string[];
    signingPrv: PrvKeyInfo | undefined;
  }

  /* eslint-disable @typescript-eslint/naming-convention */
  export type generateKey = {
    passphrase: string;
    variant: 'rsa2048' | 'rsa4096' | 'curve25519';
    userIds: { name: string; email: string }[];
  };

  export type setClientConfiguration = {
    shouldHideArmorMeta: boolean;
  };
  export type composeEmail = ComposeEmailPlain | ComposeEmailEncrypted;
  export type encryptMsg = { pubKeys: string[]; msgPwd?: string };
  export type encryptFile = { pubKeys: string[]; name: string };
  export type parseDecryptMsg = {
    keys: PrvKeyInfo[];
    msgPwd?: string;
    isMime?: boolean;
    verificationPubkeys?: string[];
  };
  export type parseAttachmentType = { atts: Attachment[] };
  export type decryptFile = { keys: PrvKeyInfo[]; msgPwd?: string };
  export type zxcvbnStrengthBar =
    | {
        guesses: number;
        purpose: 'passphrase';
        value: undefined;
        // eslint-disable-next-line @typescript-eslint/indent
      }
    | {
        value: string;
        purpose: 'passphrase';
        guesses: undefined;
        // eslint-disable-next-line @typescript-eslint/indent
      };
  export type isEmailValid = { email: string };
  export type decryptKey = { armored: string; passphrases: string[] };
  export type encryptKey = { armored: string; passphrase: string };
  export type verifyKey = { armored: string };
}
/* eslint-enable @typescript-eslint/naming-convention */

export class ValidateInput {
  public static setClientConfiguration = (v: unknown): NodeRequest.setClientConfiguration => {
    if (isObj(v) && hasProp(v, 'shouldHideArmorMeta', 'boolean?')) {
      return v as NodeRequest.setClientConfiguration;
    }
    throw new Error('Wrong request structure for NodeRequest.setClientConfiguration');
  };

  public static generateKey = (v: unknown): NodeRequest.generateKey => {
    if (
      isObj(v) &&
      hasProp(v, 'userIds', 'Userid[]') &&
      v.userIds.length &&
      hasProp(v, 'passphrase', 'string') &&
      ['rsa2048', 'rsa4096', 'curve25519'].includes(v.variant as string)
    ) {
      return v as NodeRequest.generateKey;
    }
    throw new Error('Wrong request structure for NodeRequest.generateKey');
  };

  public static encryptMsg = (v: unknown): NodeRequest.encryptMsg => {
    if (isObj(v) && hasProp(v, 'pubKeys', 'string[]') && hasProp(v, 'msgPwd', 'string?')) {
      return v as NodeRequest.encryptMsg;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptMsg');
  };

  public static composeEmail = (v: unknown): NodeRequest.composeEmail => {
    if (
      !(
        isObj(v) &&
        hasProp(v, 'text', 'string') &&
        hasProp(v, 'html', 'string?') &&
        hasProp(v, 'from', 'string') &&
        hasProp(v, 'subject', 'string') &&
        hasProp(v, 'to', 'string[]') &&
        hasProp(v, 'cc', 'string[]') &&
        hasProp(v, 'bcc', 'string[]')
      )
    ) {
      throw new Error(
        'Wrong request structure for NodeRequest.composeEmail, ' +
          'need: text,from,subject,to,cc,bcc,atts (can use empty arr for cc/bcc, and can skip atts)',
      );
    }
    if (!hasProp(v, 'atts', 'ComposeAttachment[]?')) {
      throw new Error('Wrong atts structure for NodeRequest.composeEmail, need: {name, type, base64}');
    }
    if (
      hasProp(v, 'pubKeys', 'string[]') &&
      hasProp(v, 'signingPrv', 'PrvKeyInfo?') &&
      v.pubKeys.length &&
      (v.format === 'encryptInline' || v.format === 'encryptPgpmime')
    ) {
      return v as NodeRequest.ComposeEmailEncrypted;
    }
    if (!v.pubKeys && v.format === 'plain') {
      return v as NodeRequest.ComposeEmailPlain;
    }
    throw new Error(
      'Wrong choice of pubKeys and format. Either pubKeys:[..]+format:encryptInline OR format:plain allowed',
    );
  };

  public static parseDecryptMsg = (v: unknown): NodeRequest.parseDecryptMsg => {
    if (
      isObj(v) &&
      hasProp(v, 'keys', 'PrvKeyInfo[]') &&
      hasProp(v, 'msgPwd', 'string?') &&
      hasProp(v, 'isMime', 'boolean?') &&
      hasProp(v, 'verificationPubkeys', 'string[]?')
    ) {
      return v as NodeRequest.parseDecryptMsg;
    }
    throw new Error('Wrong request structure for NodeRequest.parseDecryptMsg');
  };

  public static encryptFile = (v: unknown): NodeRequest.encryptFile => {
    if (isObj(v) && hasProp(v, 'pubKeys', 'string[]') && hasProp(v, 'name', 'string')) {
      return v as NodeRequest.encryptFile;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptFile');
  };

  public static parseAttachmentType = (v: unknown): NodeRequest.parseAttachmentType => {
    if (isObj(v) && hasProp(v, 'atts', 'Attachment[]')) {
      return v as NodeRequest.parseAttachmentType;
    }
    throw new Error('Wrong request structure for NodeRequest.parseAttachmentType');
  };

  public static decryptFile = (v: unknown): NodeRequest.decryptFile => {
    if (isObj(v) && hasProp(v, 'keys', 'PrvKeyInfo[]') && hasProp(v, 'msgPwd', 'string?')) {
      return v as NodeRequest.decryptFile;
    }
    throw new Error('Wrong request structure for NodeRequest.decryptFile');
  };

  public static zxcvbnStrengthBar = (v: unknown): NodeRequest.zxcvbnStrengthBar => {
    if (isObj(v) && hasProp(v, 'guesses', 'number') && hasProp(v, 'purpose', 'string') && v.purpose === 'passphrase') {
      return v as NodeRequest.zxcvbnStrengthBar;
    }
    if (isObj(v) && hasProp(v, 'value', 'string') && hasProp(v, 'purpose', 'string') && v.purpose === 'passphrase') {
      return v as NodeRequest.zxcvbnStrengthBar;
    }
    throw new Error('Wrong request structure for NodeRequest.zxcvbnStrengthBar');
  };

  public static isEmailValid = (v: unknown): NodeRequest.isEmailValid => {
    if (isObj(v) && hasProp(v, 'email', 'string')) {
      return v as NodeRequest.isEmailValid;
    }
    throw new Error('Wrong request structure for NodeRequest.isEmailValid');
  };

  public static decryptKey = (v: unknown): NodeRequest.decryptKey => {
    if (isObj(v) && hasProp(v, 'armored', 'string') && hasProp(v, 'passphrases', 'string[]')) {
      return v as NodeRequest.decryptKey;
    }
    throw new Error('Wrong request structure for NodeRequest.decryptKey');
  };

  public static encryptKey = (v: unknown): NodeRequest.encryptKey => {
    if (isObj(v) && hasProp(v, 'armored', 'string') && hasProp(v, 'passphrase', 'string')) {
      return v as NodeRequest.encryptKey;
    }
    throw new Error('Wrong request structure for NodeRequest.encryptKey');
  };

  public static verifyKey = (v: unknown): NodeRequest.verifyKey => {
    if (isObj(v) && hasProp(v, 'armored', 'string')) {
      return v as NodeRequest.verifyKey;
    }
    throw new Error('Wrong request structure for NodeRequest.verifyKey');
  };
}

const isObj = (v: unknown): v is Obj => {
  return !!v && typeof v === 'object';
};

const hasProp = (
  v: Obj,
  name: string,
  type:
    | 'string[]'
    | 'string[]?'
    | 'object'
    | 'string'
    | 'number'
    | 'string?'
    | 'boolean?'
    | 'PrvKeyInfo?'
    | 'PrvKeyInfo[]'
    | 'Userid[]'
    | 'ComposeAttachment[]?'
    | 'Attachment[]',
): boolean => {
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
  /* eslint-disable */
  if (type === 'ComposeAttachment[]?') {
    return (
      typeof value === 'undefined' ||
      (Array.isArray(value) &&
        value.filter(
          (x: any) => hasProp(x, 'name', 'string') && hasProp(x, 'type', 'string') && hasProp(x, 'base64', 'string'),
        ).length === value.length)
    );
  }
  if (type === 'Attachment[]') {
    return (
      Array.isArray(value) &&
      value.filter(
        (x: any) =>
          hasProp(x, 'id', 'string') &&
          hasProp(x, 'msgId', 'string') &&
          hasProp(x, 'name', 'string') &&
          hasProp(x, 'type', 'string?'),
      ).length === value.length
    );
  }
  if (type === 'string[]') {
    return Array.isArray(value) && value.filter((x: any) => typeof x === 'string').length === value.length;
  }
  if (type === 'string[]?') {
    return (
      typeof value === 'undefined' ||
      (Array.isArray(value) && value.filter((x: any) => typeof x === 'string').length === value.length)
    );
  }
  if (type === 'PrvKeyInfo?') {
    if (value === null) {
      v[name] = undefined;
      return true;
    }
    return (
      typeof value === 'undefined' ||
      (hasProp(value, 'private', 'string') &&
        hasProp(value, 'longid', 'string') &&
        hasProp(value, 'passphrase', 'string?'))
    );
  }
  if (type === 'PrvKeyInfo[]') {
    return (
      Array.isArray(value) &&
      value.filter(
        (ki: any) =>
          hasProp(ki, 'private', 'string') && hasProp(ki, 'longid', 'string') && hasProp(ki, 'passphrase', 'string?'),
      ).length === value.length
    );
  }
  if (type === 'Userid[]') {
    return (
      Array.isArray(value) &&
      value.filter((ui: any) => hasProp(ui, 'name', 'string') && hasProp(ui, 'email', 'string')).length === value.length
    );
  }
  /* eslint-enable */
  if (type === 'object') {
    return isObj(value);
  }
  return false;
};

export const readArmoredKeyOrThrow = async (armored: string) => {
  const key = await readKey({ armoredKey: armored });
  if (!key) {
    throw new Error('No key found');
  }
  return key;
};
