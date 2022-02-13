/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

interface BaseStream<T extends Uint8Array | string> extends AsyncIterable<T> { }

interface WebStream<T extends Uint8Array | string> extends BaseStream<T> { // copied+simplified version of ReadableStream from lib.dom.d.ts
  readonly locked: boolean; getReader: Function; pipeThrough: Function; pipeTo: Function; tee: Function;
  cancel(reason?: any): Promise<void>;
}

interface NodeStream<T extends Uint8Array | string> extends BaseStream<T> { // copied+simplified version of ReadableStream from @types/node/index.d.ts
  readable: boolean; pipe: Function; unpipe: Function; wrap: Function;
  read(size?: number): string | Uint8Array; setEncoding(encoding: string): this; pause(): this; resume(): this;
  isPaused(): boolean; unshift(chunk: string | Uint8Array): void;
}

type ReadToEndFn = <T extends Uint8Array | string>(input: T | WebStream<T> | NodeStream<T>, concat?: (list: T[]) => T) => Promise<T>;

export const requireStreamReadToEnd = (): ReadToEndFn => {
  // this will work for running tests in node with build/ts/test.js as entrypoint
  // a different solution will have to be done for running in iOS
  (global as any)['window'] = (global as any)['window'] || {}; // web-stream-tools needs this
  const { readToEnd } = require('../../bundles/raw/web-stream-tools');
  return readToEnd as ReadToEndFn;
}

export const requireMimeParser = (): any => {
  // @ts-ignore;
  return global['emailjs-mime-parser'];
};

export const requireMimeBuilder = (): any => {
  // global['emailjs-mime-builder'] ?
  // dereq_emailjs_mime_builder ?
  // @ts-ignore
  return global['emailjs-mime-builder'];
};

export const requireIso88592 = (): any => {
  // @ts-ignore
  return global['iso88592'];
};
