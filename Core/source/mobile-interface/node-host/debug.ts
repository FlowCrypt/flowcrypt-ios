/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

import { Buf } from '../../core/buf';

export class Debug {

  public static printChunk = (name: string, data: Buf | Uint8Array) => {
    const header1 = `Debug.printChunk[${name}, ${data.length}B]: `;
    const header2 = ' '.repeat(header1.length);
    const chunk = Array.from(data.subarray(0, 30));
    const chunkIndices = chunk.map((_, i) => i);
    console.log(`-\n${header1} - +-[${chunk.map(Debug.pad).join(' ')}]\n${header2} | -[${chunk.map(Debug.char).map(Debug.pad).join(' ')}]\n${header2} \`-[${chunkIndices.map(Debug.pad).join(' ')} ]`);
  }

  private static char = (byte: number) => {
    let c = ''
    if (byte === 10) {
      c += '\\n';
    } else if (byte === 13) {
      c += '\\r';
    } else if (byte === 140 || byte === 160) {
      c += '???';
    } else {
      c += String.fromCharCode(byte);
    }
    return c;
  }

  private static pad = (char: string | number) => {
    char = String(char);
    while (char.length < 3) {
      char = ' ' + char;
    }
    return char;
  }
}
