/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { MsgBlock, ReplaceableMsgBlockType } from './msg-block';

import { Catch } from '../platform/catch';
import { PgpArmor } from './crypto/pgp/pgp-armor';
import { Str } from './common';
import { KeyUtil } from './crypto/key';

export class MsgBlockParser {

  private static ARMOR_HEADER_MAX_LENGTH = 50;

  public static detectBlocks = (origText: string) => {
    const blocks: MsgBlock[] = [];
    const normalized = Str.normalize(origText);
    let startAt = 0;
    while (true) { // eslint-disable-line no-constant-condition
      const { found, continueAt } = MsgBlockParser.detectBlockNext(normalized, startAt);
      if (found) {
        blocks.push(...found);
      }
      if (typeof continueAt === 'undefined') {
        return { blocks, normalized };
      } else {
        if (continueAt <= startAt) {
          Catch.report(`MsgBlockParser.detectBlocks likely infinite loop: r.continueAt(${continueAt}) <= startAt(${startAt})`);
          return { blocks, normalized }; // prevent infinite loop
        }
        startAt = continueAt;
      }
    }
  }

  public static stripFcTeplyToken = (decryptedContent: string) => {
    return decryptedContent.replace(/<div[^>]+class="cryptup_reply"[^>]+><\/div>/, '');
  }

  private static detectBlockNext = (origText: string, startAt: number) => {
    const armorHdrTypes = Object.keys(PgpArmor.ARMOR_HEADER_DICT) as ReplaceableMsgBlockType[];
    const result: { found: MsgBlock[], continueAt?: number } = { found: [] as MsgBlock[] };
    const begin = origText.indexOf(PgpArmor.headers('null').begin, startAt);
    if (begin !== -1) { // found
      const potentialBeginHeader = origText.substr(begin, MsgBlockParser.ARMOR_HEADER_MAX_LENGTH);
      for (const armorHdrType of armorHdrTypes) {
        const blockHeaderDef = PgpArmor.ARMOR_HEADER_DICT[armorHdrType];
        if (blockHeaderDef.replace) {
          const indexOfConfirmedBegin = potentialBeginHeader.indexOf(blockHeaderDef.begin);
          if (indexOfConfirmedBegin === 0) {
            if (begin > startAt) {
              let potentialTextBeforeBlockBegun = origText.substring(startAt, begin);
              if (!potentialTextBeforeBlockBegun.endsWith('\n')) {
                // only replace blocks if they begin on their own line
                // contains deliberate block: `-----BEGIN PGP PUBLIC KEY BLOCK-----\n...`
                // contains deliberate block: `Hello\n-----BEGIN PGP PUBLIC KEY BLOCK-----\n...`
                // just plaintext (accidental block): `Hello -----BEGIN PGP PUBLIC KEY BLOCK-----\n...`
                continue; // block treated as plaintext, not on dedicated line - considered accidental
                // this will actually cause potential deliberate blocks that follow accidental block to be ignored
                // but if the message already contains accidental (not on dedicated line) blocks, it's probably a good thing to ignore the rest
              }
              potentialTextBeforeBlockBegun = potentialTextBeforeBlockBegun.trim();
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
              result.found.push(MsgBlock.fromContent(armorHdrType, origText.substring(begin, endIndex + foundBlockEndHeaderLength).trim()));
              result.continueAt = endIndex + foundBlockEndHeaderLength;
            } else { // corresponding end not found
              result.found.push(MsgBlock.fromContent(armorHdrType, origText.substr(begin), true));
            }
            break;
          }
        }
      }
    }
    if (origText && !result.found.length) { // didn't find any blocks, but input is non-empty
      const potentialText = origText.substr(startAt).trim();
      if (potentialText) {
        result.found.push(MsgBlock.fromContent('plainText', potentialText));
      }
    }
    return result;
  }

  private static pushArmoredPubkeysToBlocks = async (armoredPubkeys: string[], blocks: MsgBlock[]): Promise<void> => {
    for (const armoredPubkey of armoredPubkeys) {
      const keys = await KeyUtil.parseMany(armoredPubkey);
      for (const key of keys) {
        const pub = await KeyUtil.asPublicKey(key);
        blocks.push(MsgBlock.fromContent('publicKey', KeyUtil.armor(pub)));
      }
    }
  }

}
