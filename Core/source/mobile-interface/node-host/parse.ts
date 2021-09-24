/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Buffers } from '../format-output';
import { HttpClientErr } from '../node-host/errs';
import { Debug } from './debug';
import { IncomingMessage } from 'http';

type ParseRes = { endpoint: string, data: Buffers, request: {} };
const NEWLINE = Buffer.from('\n');

export const parseReq = (r: IncomingMessage, debug: boolean): Promise<ParseRes> => new Promise((resolve, reject) => {
  const initBuffers: Buffers = [];
  const data: Buffers = [];
  let newlinesEncountered = 0;
  let totalLen = 0;
  r.on('data', (chunk: Buffer) => {
    if (debug) {
      totalLen += chunk.length;
      Debug.printChunk(`http chunk`, chunk);
    }
    let byteOffset = 0;
    while (newlinesEncountered < 2) {
      const nextNewlineIndex = chunk.indexOf(NEWLINE, byteOffset);
      if (nextNewlineIndex === -1) {
        initBuffers.push(chunk.subarray(byteOffset));
        return;
      }
      const beginNextLine = nextNewlineIndex + NEWLINE.length;
      initBuffers.push(chunk.slice(byteOffset, beginNextLine));
      byteOffset = beginNextLine;
      newlinesEncountered++;
    }
    data.push(chunk.slice(byteOffset));
  });
  r.on('end', () => {
    if (debug) {
      const initLen = initBuffers.map(b => b.length).reduce((a, b) => a + b);
      const dataLen = data.map(b => b.length).reduce((a, b) => a + b);
      console.log(`Reached end of stream. Total stream length: ${totalLen} of which ${initLen} was first two lines and ${dataLen} was data`);
      for (let i = 0; i < initBuffers.length; i++) {
        Debug.printChunk(`initBuffer ${i}`, initBuffers[i]);
      }
      for (let i = 0; i < data.length; i++) {
        Debug.printChunk(`dataBuffer ${i}`, data[i]);
      }
    }
    if (initBuffers.length && data.length) {
      const [endpointLine, requestLine] = Buffer.concat(initBuffers).toString().split(Buffer.from(NEWLINE).toString());
      if (debug) {
        Debug.printChunk('endpointLine', Buffer.from(endpointLine));
        Debug.printChunk('requestLine', Buffer.from(requestLine));
      }
      try {
        const request = JSON.parse(requestLine.trim());
        const endpoint = endpointLine.trim();
        resolve({ endpoint, request, data });
      } catch (e) {
        if (debug) {
          console.log('---- begin faulty input ----');
          console.log(requestLine);
          console.log('---- end faulty input ----');
        }
        reject(new HttpClientErr(`cannot parse request part as json: ${String(e)}`));
      }
    } else {
      reject(new HttpClientErr('missing endpoint or request part'));
    }

  });
})
