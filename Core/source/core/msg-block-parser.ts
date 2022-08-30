/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { MsgBlock, ReplaceableMsgBlockType } from './msg-block';
import { Xss } from '../platform/xss';

import { Buf } from './buf';
import { Catch } from '../platform/catch';
import { Mime } from './mime';
import { PgpArmor } from './pgp-armor';
import { PgpKey } from './pgp-key';
import { PgpMsg, VerifyRes } from './pgp-msg';
import { Str } from './common';

type SanitizedBlocks = { blocks: MsgBlock[], subject: string | undefined, isRichText: boolean };

export class MsgBlockParser {

  // eslint-disable-next-line @typescript-eslint/naming-convention
  private static ARMOR_HEADER_MAX_LENGTH = 50;

  public static detectBlocks = (origText: string) => {
    const blocks: MsgBlock[] = [];
    const normalized = Str.normalize(origText);
    let startAt = 0;
    while (true) {
      const r = MsgBlockParser.detectBlockNext(normalized, startAt);
      if (r.found) {
        blocks.push(...r.found);
      }
      if (typeof r.continueAt === 'undefined') {
        return { blocks, normalized };
      } else {
        if (r.continueAt <= startAt) {
          Catch.report(`PgpArmordetect_blocks likely infinite loop: r.continue_at(${r.continueAt})` +
            ` <= start_at(${startAt})`);
          return { blocks, normalized }; // prevent infinite loop
        }
        startAt = r.continueAt;
      }
    }
  };

  public static fmtDecryptedAsSanitizedHtmlBlocks = async (
    decryptedContent: Uint8Array, signature?: VerifyRes): Promise<SanitizedBlocks> => {
    const blocks: MsgBlock[] = [];
    let isRichText = false;
    if (!Mime.resemblesMsg(decryptedContent)) {
      let utf = Buf.fromUint8(decryptedContent).toUtfStr();
      utf = PgpMsg.extractFcAtts(utf, blocks);
      utf = PgpMsg.stripFcTeplyToken(utf);
      const armoredPubKeys: string[] = [];
      utf = PgpMsg.stripPublicKeys(utf, armoredPubKeys);
      const block = MsgBlock.fromContent('decryptedHtml', Str.asEscapedHtml(utf));
      block.verifyRes = signature;
      blocks.push(block); // escaped text as html
      await MsgBlockParser.pushArmoredPubkeysToBlocks(armoredPubKeys, blocks);
      return { blocks, subject: undefined, isRichText };
    }
    const decoded = await Mime.decode(decryptedContent);
    if (typeof decoded.html !== 'undefined') {
      const block = MsgBlock.fromContent('decryptedHtml', Xss.htmlSanitizeKeepBasicTags(decoded.html));
      block.verifyRes = signature;
      blocks.push(block); // sanitized html
      isRichText = true;
    } else if (typeof decoded.text !== 'undefined') {
      const block = MsgBlock.fromContent('decryptedHtml', Str.asEscapedHtml(decoded.text));
      block.verifyRes = signature;
      blocks.push(block); // escaped text as html
    } else {
      const block = MsgBlock.fromContent('decryptedHtml', Str.asEscapedHtml(Buf.with(decryptedContent).toUtfStr()));
      block.verifyRes = signature;
      blocks.push(); // escaped mime text as html
    }
    for (const att of decoded.atts) {
      if (att.treatAs() === 'publicKey') {
        await MsgBlockParser.pushArmoredPubkeysToBlocks([att.getData().toUtfStr()], blocks);
      } else {
        const block = MsgBlock.fromAtt('decryptedAtt', '',
          { name: att.name, data: att.getData(), length: att.length, type: att.type });
        block.verifyRes = signature;
        blocks.push(block);
      }
    }
    return { blocks, subject: decoded.subject, isRichText };
  };

  private static detectBlockNext = (origText: string, startAt: number) => {
    const result: { found: MsgBlock[], continueAt?: number } = { found: [] as MsgBlock[] };
    const begin = origText.indexOf(PgpArmor.headers('null').begin, startAt);
    if (begin !== -1) { // found
      const potentialBeginHeader = origText.substring(begin, begin + MsgBlockParser.ARMOR_HEADER_MAX_LENGTH);
      for (const xType of Object.keys(PgpArmor.ARMOR_HEADER_DICT)) {
        const type = xType as ReplaceableMsgBlockType;
        const blockHeaderDef = PgpArmor.ARMOR_HEADER_DICT[type];
        if (blockHeaderDef.replace) {
          const indexOfConfirmedBegin = potentialBeginHeader.indexOf(blockHeaderDef.begin);
          if (indexOfConfirmedBegin === 0
            || (type === 'encryptedMsgLink' && indexOfConfirmedBegin >= 0 && indexOfConfirmedBegin < 15)) {
            // identified beginning of a specific block
            if (begin > startAt) {
              const potentialTextBeforeBlockBegun = origText.substring(startAt, begin).trim();
              if (potentialTextBeforeBlockBegun) {
                result.found.push(MsgBlock.fromContent('plainText', potentialTextBeforeBlockBegun));
              }
            }
            let endIndex = -1;
            let foundBlockEndHeaderLength = 0;
            if (typeof blockHeaderDef.end === 'string') {
              endIndex = origText.indexOf(blockHeaderDef.end, begin + blockHeaderDef.begin.length);
              foundBlockEndHeaderLength = blockHeaderDef.end.length;
            } else { // regexp
              const origTextAfterBeginIndex = origText.substring(begin);
              const matchEnd = origTextAfterBeginIndex.match(blockHeaderDef.end);
              if (matchEnd) {
                endIndex = matchEnd.index ? begin + matchEnd.index : -1;
                foundBlockEndHeaderLength = matchEnd[0].length;
              }
            }
            if (endIndex !== -1) { // identified end of the same block
              if (type !== 'encryptedMsgLink') {
                result.found.push(MsgBlock.fromContent(
                  type, origText.substring(begin, endIndex + foundBlockEndHeaderLength).trim()));
              } else {
                const pwdMsgFullText = origText.substring(begin, endIndex + foundBlockEndHeaderLength).trim();
                const pwdMsgShortIdMatch = pwdMsgFullText.match(/[a-zA-Z0-9]{10}$/);
                if (pwdMsgShortIdMatch) {
                  result.found.push(MsgBlock.fromContent(type, pwdMsgShortIdMatch[0]));
                } else {
                  result.found.push(MsgBlock.fromContent('plainText', pwdMsgFullText));
                }
              }
              result.continueAt = endIndex + foundBlockEndHeaderLength;
            } else { // corresponding end not found
              result.found.push(MsgBlock.fromContent(type, origText.substring(begin), true));
            }
            break;
          }
        }
      }
    }
    if (origText && !result.found.length) { // didn't find any blocks, but input is non-empty
      const potentialText = origText.substring(startAt).trim();
      if (potentialText) {
        result.found.push(MsgBlock.fromContent('plainText', potentialText));
      }
    }
    return result;
  };

  private static pushArmoredPubkeysToBlocks = async (armoredPubkeys: string[], blocks: MsgBlock[]): Promise<void> => {
    for (const armoredPubkey of armoredPubkeys) {
      const { keys } = await PgpKey.parse(armoredPubkey);
      for (const keyDetails of keys) {
        blocks.push(MsgBlock.fromKeyDetails('publicKey', keyDetails.public, keyDetails));
      }
    }
  };

}
