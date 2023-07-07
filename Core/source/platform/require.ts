/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

export interface BaseStream<T extends Uint8Array | string> extends AsyncIterable<T> {}

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
export const requireStreamReadToEnd = async (): Promise<ReadToEndFn> => {
  const runtime = globalThis.process?.release?.name || 'not node';
  return runtime === 'not node'
    ? (await import('@openpgp/web-stream-tools')).readToEnd
    : require('../../bundles/raw/web-stream-tools').readToEnd;
};

export const requireMimeParser = () => {
  // @ts-ignore;
  return global['emailjs-mime-parser'];
};

export const requireMimeBuilder = () => {
  // global['emailjs-mime-builder'] ?
  // dereq_emailjs_mime_builder ?
  // @ts-ignore
  return global['emailjs-mime-builder'];
};

export const requireIso88592 = () => {
  // @ts-ignore
  return global.iso88592;
};

/* eslint-enable */
