/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

export interface BaseStream<T extends Uint8Array | string> extends AsyncIterable<T> { }

// copied+simplified version of ReadableStream from lib.dom.d.ts
export interface WebStream<T extends Uint8Array | string> extends BaseStream<T> {
  readonly locked: boolean;
  getReader: () => void;
  pipeThrough: () => void;
  pipeTo: () => void;
  tee: () => void;
  cancel(reason?: unknown): Promise<void>;
}

// copied+simplified version of ReadableStream from @types/node/index.d.ts
export interface NodeStream<T extends Uint8Array | string> extends BaseStream<T> {
  readable: boolean;
  pipe: () => void;
  unpipe: () => void;
  wrap: () => void;
  read(size?: number): string | Uint8Array;
  setEncoding(encoding: string): this;
  pause(): this;
  resume(): this;
  isPaused(): boolean;
  unshift(chunk: string | Uint8Array): void;
}

export type MaybeStream<T extends Uint8Array | string> = T | WebStream<T> | NodeStream<T>;

type ReadToEndFn = <T extends Uint8Array | string>(input: MaybeStream<T>, concat?: (list: T[]) => T) => Promise<T>;

/* eslint-disable */
export const requireStreamReadToEnd = (): ReadToEndFn => {
  // this will work for running tests in node with build/ts/test.js as entrypoint
  // a different solution will have to be done for running in iOS
  (global as any).window = (global as any).window || {}; // web-stream-tools needs this
  const { readToEnd } = require('../../bundles/raw/web-stream-tools');
  return readToEnd as ReadToEndFn;
};

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
  return global.iso88592;
};

/* eslint-enable */