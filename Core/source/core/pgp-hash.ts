/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { util, Sha1, Sha256 } from '../lib/openpgp';
import { Buf } from './buf';

export class PgpHash {

  public static sha1UtfStr = async (string: string): Promise<string> => {
    return util.uint8ArrayToHex((new Sha1()).process(Buf.fromUtfStr(string)).finish().result);
  }

  public static sha256UtfStr = async (string: string) => {
    return util.uint8ArrayToHex((new Sha256()).process(Buf.fromUtfStr(string)).finish().result);
  }

  public static doubleSha1Upper = async (string: string) => {
    return (await PgpHash.sha1UtfStr(await PgpHash.sha1UtfStr(string))).toUpperCase();
  }

  public static challengeAnswer = async (answer: string) => {
    return await PgpHash.cryptoHashSha256Loop(answer);
  }

  private static cryptoHashSha256Loop = async (string: string, times = 100000) => {
    for (let i = 0; i < times; i++) {
      string = await PgpHash.sha256UtfStr(string);
    }
    return string;
  }

}
