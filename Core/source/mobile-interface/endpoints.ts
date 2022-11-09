/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buffers, EndpointRes, fmtContentBlock, fmtRes, isContentBlock, removeUndefinedValues } from './format-output';
import { DecryptErrTypes, PgpMsg } from '../core/pgp-msg';
import { KeyDetails, PgpKey } from '../core/pgp-key';
import { Mime, RichHeaders, SendableMsgBody } from '../core/mime';

import { Att } from '../core/att';
import { Buf } from '../core/buf';
import { MsgBlock } from '../core/msg-block';
import { MsgBlockParser } from '../core/msg-block-parser';
import { PgpPwd } from '../core/pgp-password';
import { Store } from '../platform/store';
import { Str } from '../core/common';
import { VERSION } from '../core/const';
import { ValidateInput, readArmoredKeyOrThrow, NodeRequest } from './validate-input';
import { Xss } from '../platform/xss';
import { gmailBackupSearchQuery } from '../core/const';
import { config, encryptKey, Key, PrivateKey, readKey, readKeys } from 'openpgp';

export class Endpoints {

  [endpoint: string]: ((uncheckedReq: unknown, data: Buffers) => Promise<EndpointRes>) | undefined;

  public version = async (): Promise<EndpointRes> => {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    return fmtRes({ app_version: VERSION });
  };

  public setClientConfiguration = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const { shouldHideArmorMeta } = ValidateInput.setClientConfiguration(uncheckedReq);
    config.showVersion = !shouldHideArmorMeta;
    config.showComment = !shouldHideArmorMeta;
    return fmtRes({});
  };

  public generateKey = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    Store.keyCacheWipe(); // generateKey may be used when changing major settings, wipe cache to prevent dated results
    const { passphrase, userIds, variant } = ValidateInput.generateKey(uncheckedReq);
    if (passphrase.length < 12) {
      throw new Error(
        'Pass phrase length seems way too low! ' +
        'Pass phrase strength should be properly checked before encrypting a key.');
    }
    const k = await PgpKey.create(userIds, variant, passphrase);
    return fmtRes({ key: await PgpKey.details(await PgpKey.read(k.private)) });
  };

  public composeEmail = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const req = ValidateInput.composeEmail(uncheckedReq);
    const mimeHeaders: RichHeaders = { to: req.to, from: req.from, subject: req.subject, cc: req.cc, bcc: req.bcc };

    if (req.replyToMsgId) {
      mimeHeaders['in-reply-to'] = req.replyToMsgId;
      mimeHeaders.references = [req.inReplyTo, req.replyToMsgId]
        .filter(value => !!value)
        .join(' ');
    }

    if (req.format === 'plain') {
      const atts = (req.atts || []).map(({ name, type, base64 }) =>
        new Att({ name, type, data: Buf.fromBase64Str(base64) }));
      // eslint-disable-next-line @typescript-eslint/naming-convention
      const body: SendableMsgBody = { 'text/plain': req.text };
      if (req.html) {
        body['text/html'] = req.html;
      }
      return fmtRes({}, Buf.fromUtfStr(await Mime.encode(body, mimeHeaders, atts)));
    } else if (req.format === 'encryptInline') {
      const encryptedAtts: Att[] = [];
      for (const att of req.atts || []) {
        const encryptedAtt = await PgpMsg.encrypt({
          pubkeys: req.pubKeys,
          data: Buf.fromBase64Str(att.base64),
          filename: att.name,
          armor: false
        }) as Uint8Array;
        encryptedAtts.push(new Att({
          name: `${att.name}.pgp`,
          type: 'application/pgp-encrypted',
          data: encryptedAtt
        }));
      }

      const signingPrv = await getSigningPrv(req);
      const encrypted = await PgpMsg.encrypt({
        pubkeys: req.pubKeys,
        signingPrv,
        data: Buf.fromUtfStr(req.text),
        armor: true
      }) as string;
      // eslint-disable-next-line @typescript-eslint/naming-convention
      return fmtRes({}, Buf.fromUtfStr(await Mime.encode({ 'text/plain': encrypted }, mimeHeaders, encryptedAtts)));
    } else {
      throw new Error(`Unknown format: ${req.format}`);
    }
  };

  public encryptMsg = async (uncheckedReq: unknown, data: Buffers): Promise<EndpointRes> => {
    const req = ValidateInput.encryptMsg(uncheckedReq);
    const encrypted = await PgpMsg.encrypt(
      { pubkeys: req.pubKeys, pwd: req.msgPwd, data: Buf.concat(data), armor: true }) as string;
    return fmtRes({}, Buf.fromUtfStr(encrypted));
  };

  public encryptFile = async (uncheckedReq: unknown, data: Buffers): Promise<EndpointRes> => {
    const req = ValidateInput.encryptFile(uncheckedReq);
    const encrypted = await PgpMsg.encrypt(
      { pubkeys: req.pubKeys, data: Buf.concat(data), filename: req.name, armor: false }) as Uint8Array;
    return fmtRes({}, encrypted);
  };

  public parseDecryptMsg = async (uncheckedReq: unknown, data: Buffers): Promise<EndpointRes> => {
    const { keys: kisWithPp, msgPwd, isMime, verificationPubkeys } = ValidateInput.parseDecryptMsg(uncheckedReq);
    const rawBlocks: MsgBlock[] = []; // contains parsed, unprocessed / possibly encrypted data
    let rawSigned: string | undefined;
    let subject: string | undefined;
    if (isMime) {
      const { blocks, rawSignedContent, headers } = await Mime.process(Buf.concat(data));
      subject = String(headers.subject);
      rawSigned = rawSignedContent;
      rawBlocks.push(...blocks);
    } else {
      const { blocks } = MsgBlockParser.detectBlocks(Buf.concat(data).toString());
      rawBlocks.push(...blocks);
    }
    const sequentialProcessedBlocks: MsgBlock[] = []; // contains decrypted or otherwise formatted data
    for (const rawBlock of rawBlocks) {
      if ((rawBlock.type === 'signedMsg' || rawBlock.type === 'signedHtml') && rawBlock.signature) {
        const verify = await PgpMsg.verifyDetached({
          sigText: Buf.fromUtfStr(rawBlock.signature),
          plaintext: Buf.with(rawSigned || rawBlock.content),
          verificationPubkeys
        });
        if (rawBlock.type === 'signedHtml') {
          sequentialProcessedBlocks.push({
            type: 'verifiedMsg',
            content: Xss.htmlSanitizeKeepBasicTags(rawBlock.content.toString()),
            verifyRes: verify,
            complete: true
          });
        } else { // text
          sequentialProcessedBlocks.push({
            type: 'verifiedMsg',
            content: Str.asEscapedHtml(rawBlock.content.toString()),
            verifyRes: verify,
            complete: true
          });
        }
      } else if (rawBlock.type === 'encryptedMsg' || rawBlock.type === 'signedMsg') {
        const decryptRes = await PgpMsg.decrypt({
          kisWithPp,
          msgPwd,
          encryptedData: Buf.with(rawBlock.content),
          verificationPubkeys
        });
        if (decryptRes.success) {
          if (decryptRes.isEncrypted) {
            const formatted = await MsgBlockParser.fmtDecryptedAsSanitizedHtmlBlocks(
              decryptRes.content, decryptRes.signature);
            sequentialProcessedBlocks.push(...formatted.blocks);
            subject = formatted.subject || subject;
          } else {
            // treating as text, converting to html - what about plain signed html? This could produce html tags
            // although hopefully, that would, typically, result in the
            // `(rawBlock.type === 'signedMsg' || rawBlock.type === 'signedHtml')` block above
            // the only time I can imagine it screwing up down here is if it was a signed-only message
            // that was actually fully armored (text not visible) with a mime msg inside
            // ... -> in which case the user would I think see full mime content?
            sequentialProcessedBlocks.push({
              type: 'verifiedMsg',
              content: Str.asEscapedHtml(decryptRes.content.toUtfStr()),
              complete: true,
              verifyRes: decryptRes.signature
            });
          }
        } else {
          delete decryptRes.message;
          sequentialProcessedBlocks.push({
            type: 'decryptErr',
            content: decryptRes.error.type === DecryptErrTypes.noMdc
              ? decryptRes.content?.toUtfStr() ?? '' : rawBlock.content.toString(),
            decryptErr: decryptRes,
            complete: true
          });
        }
      } else if (rawBlock.type === 'encryptedAtt'
        && rawBlock.attMeta
        && /^(0x)?[A-Fa-f0-9]{16,40}\.asc\.pgp$/.test(rawBlock.attMeta.name || '')) {
        // encrypted pubkey attached
        const decryptRes = await PgpMsg.decrypt({
          kisWithPp,
          msgPwd,
          encryptedData: Buf.with(rawBlock.attMeta.data || ''),
          verificationPubkeys
        });
        if (decryptRes.content) {
          sequentialProcessedBlocks.push({ type: 'publicKey', content: decryptRes.content.toString(), complete: true });
        } else {
          sequentialProcessedBlocks.push(rawBlock); // will show as encryptedAtt
        }
      } else {
        sequentialProcessedBlocks.push(rawBlock);
      }
    }
    // At this point we have sequentialProcessedBlocks filled
    const msgContentBlocks: MsgBlock[] = [];
    const blocks: MsgBlock[] = [];
    let replyType = 'plain';
    for (const block of sequentialProcessedBlocks) { // fix/adjust/format blocks before returning it over JSON
      if (block.content instanceof Buf) { // cannot JSON-serialize Buf
        block.content = isContentBlock(block.type)
          ? block.content.toUtfStr()
          : block.content.toRawBytesStr();
      } else if (block.attMeta && block.attMeta.data instanceof Uint8Array) {
        // converting to base64-encoded string instead of uint8 for JSON serilization
        // value actually replaced to a string, but type remains Uint8Array type set to satisfy TS
        // no longer used below, only gets passed to be serialized as JSON - later consumed by iOS or Android app
        block.attMeta.data = Buf.fromUint8(block.attMeta.data).toBase64Str() as unknown as Uint8Array;
      }
      if (block.decryptErr?.content instanceof Buf) {
        // cannot pass a Buf using a json, converting to String before it gets serialized
        block.decryptErr.content = block.decryptErr.content.toUtfStr() as unknown as Buf;
      }
      if (block.type === 'decryptedHtml' || block.type === 'decryptedText' || block.type === 'decryptedAtt') {
        replyType = 'encrypted';
      }
      if (block.type === 'publicKey') {
        if (!block.keyDetails) { // this could eventually be moved into detectBlocks, which would make it async
          const { keys } = await PgpKey.normalize(block.content);
          if (keys.length) {
            for (const pub of keys) {
              blocks.push({
                type: 'publicKey',
                content: pub.armor(),
                complete: true,
                keyDetails: await PgpKey.details(pub)
              });
            }
          } else {
            blocks.push({
              type: 'decryptErr',
              content: block.content,
              complete: true,
              decryptErr: {
                success: false,
                error: { type: DecryptErrTypes.format, message: 'Badly formatted public key' },
                longids: { message: [], matching: [], chosen: [], needPassphrase: [] }
              }
            });
          }
        } else {
          blocks.push(block);
        }
      } else if (isContentBlock(block.type)) {
        msgContentBlocks.push(block);
      } else if (Mime.isPlainImgAtt(block)) {
        msgContentBlocks.push(block);
      } else {
        blocks.push(block);
      }
    }
    const { contentBlock, text } = fmtContentBlock(msgContentBlocks);
    blocks.unshift(contentBlock);
    // data represent one JSON-stringified block per line. This is so that it can be read as a stream later
    const blocksData = Buf.fromUtfStr(blocks.map(b => {
      return JSON.stringify(b, (key, value) => {
        // 'content' is used only for error messages on iOS
        // sending empty string for large messages improves decrypt performance
        if (key === 'content' && value.length > 100000) {
          return '';
        }
        return `${value}`;
      });
    }).join('\n'));
    const json = { text, replyType };
    if (subject) { Object.assign(json, { subject }); }
    return fmtRes(json, blocksData);
  };

  public decryptFile = async (uncheckedReq: unknown, data: Buffers, verificationPubkeys?: string[]):
    Promise<EndpointRes> => {
    const { keys: kisWithPp, msgPwd } = ValidateInput.decryptFile(uncheckedReq);
    const decryptRes = await PgpMsg.decrypt({
      kisWithPp,
      encryptedData: Buf.concat(data),
      msgPwd, verificationPubkeys
    });
    if (!decryptRes.success) {
      delete decryptRes.message;
      delete decryptRes.content;
      return fmtRes({ decryptErr: decryptRes });
    }
    return fmtRes({ decryptSuccess: { name: decryptRes.filename || '' } }, decryptRes.content);
  };

  public parseDateStr = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const { dateStr } = ValidateInput.parseDateStr(uncheckedReq);
    return fmtRes({ timestamp: String(Date.parse(dateStr) || -1) });
  };

  public zxcvbnStrengthBar = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const r = ValidateInput.zxcvbnStrengthBar(uncheckedReq);
    if (r.purpose === 'passphrase') {
      if (typeof r.guesses === 'number') {
        // the host has a port of zxcvbn and already knows amount of guesses per password
        return fmtRes(PgpPwd.estimateStrength(r.guesses));
      } else if (typeof r.value === 'string') {
        // host does not have zxcvbn, let's use zxcvbn-js to estimate guesses
        type FakeWindow = { zxcvbn: (password: string, weakWords: string[]) => { guesses: number } };
        if (typeof (window as unknown as FakeWindow).zxcvbn !== 'function') {
          throw new Error("window.zxcvbn missing in js");
        }
        const guesses = (window as unknown as FakeWindow).zxcvbn(r.value, PgpPwd.weakWords()).guesses;
        return fmtRes(PgpPwd.estimateStrength(guesses));
      } else {
        throw new Error('Unexpected format: guesses is not a number, value is not a string');
      }
    } else {
      throw new Error(`Unknown purpose: ${r.purpose}`);
    }
  };

  public gmailBackupSearch = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const { acctEmail } = ValidateInput.gmailBackupSearch(uncheckedReq);
    return fmtRes({ query: gmailBackupSearchQuery(acctEmail) });
  };

  public parseKeys = async (_uncheckedReq: unknown, data: Buffers): Promise<EndpointRes> => {
    const keyDetails: KeyDetails[] = [];
    const allData = Buf.concat(data);
    const pgpType = await PgpMsg.type({ data: allData });
    if (!pgpType) {
      return fmtRes({ format: 'unknown', keyDetails });
    }
    if (pgpType.armored) {
      // armored
      const { blocks } = MsgBlockParser.detectBlocks(allData.toString());
      for (const block of blocks) {
        const { keys } = await PgpKey.parse(block.content.toString());
        keyDetails.push(...keys);
      }
      for (const keyDetail of keyDetails) {
        removeUndefinedValues(keyDetail);
      }
      return fmtRes({ format: 'armored', keyDetails });
    }
    // binary
    const openPgpKeys = await readKeys({ binaryKeys: allData });
    for (const openPgpKey of openPgpKeys) {
      keyDetails.push(await PgpKey.details(openPgpKey));
    }
    for (const keyDetail of keyDetails) {
      removeUndefinedValues(keyDetail);
    }
    return fmtRes({ format: 'binary', keyDetails });
  };

  public isEmailValid = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const { email } = ValidateInput.isEmailValid(uncheckedReq);
    return fmtRes({ valid: Str.isEmailValid(email) });
  };

  public decryptKey = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    // decryptKey may be used when changing major settings, wipe cache to prevent dated results
    Store.keyCacheWipe();
    const { armored, passphrases } = ValidateInput.decryptKey(uncheckedReq);
    if (passphrases.length !== 1) {
      // todo - refactor endpoint decryptKey api to accept a single pp
      throw new Error(`decryptKey: Can only accept exactly 1 pass phrase for decrypt, received: ${passphrases.length}`);
    }
    const key = await readArmoredKeyOrThrow(armored);
    if (await PgpKey.decrypt(key, passphrases[0])) {
      return fmtRes({ decryptedKey: key.armor() });
    }
    return fmtRes({ decryptedKey: undefined });
  };

  public encryptKey = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    // encryptKey may be used when changing major settings, wipe cache to prevent dated results
    Store.keyCacheWipe();
    const { armored, passphrase } = ValidateInput.encryptKey(uncheckedReq);
    const privateKey = await readArmoredKeyOrThrow(armored) as PrivateKey;
    if (!passphrase || passphrase.length < 12) { // last resort check, this should never happen
      throw new Error(
        'Pass phrase length seems way too low! ' +
        'Pass phrase strength should be properly checked before encrypting a key.');
    }
    const encryptedKey = await encryptKey({ privateKey, passphrase });
    return fmtRes({ encryptedKey: encryptedKey.armor() });
  };

  public verifyKey = async (uncheckedReq: unknown): Promise<EndpointRes> => {
    const { armored } = ValidateInput.verifyKey(uncheckedReq);
    const key = await readKey({ armoredKey: armored });
    await key.verifyPrimaryKey(); // throws on error
    return fmtRes({});
  };

  public keyCacheWipe = async (): Promise<EndpointRes> => {
    Store.keyCacheWipe();
    return fmtRes({});
  };
}

export const getSigningPrv = async (req: NodeRequest.ComposeEmailEncrypted): Promise<Key | undefined> => {
  if (!req.signingPrv) {
    return undefined;
  }
  const key = await readArmoredKeyOrThrow(req.signingPrv.private);
  if (await PgpKey.decrypt(key, req.signingPrv.passphrase || '')) {
    return key;
  } else {
    throw new Error(`Fail to decrypt signing key`);
  }
};
