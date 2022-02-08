export let ReadableStream: {
    new <R = any>(underlyingSource?: UnderlyingSource<R>, strategy?: QueuingStrategy<R>): ReadableStream<R>;
    prototype: ReadableStream<any>;
};
export let WritableStream: {
    new <W = any>(underlyingSink?: UnderlyingSink<W>, strategy?: QueuingStrategy<W>): WritableStream<W>;
    prototype: WritableStream<any>;
};
export let TransformStream: {
    new <I = any, O = any>(transformer?: Transformer<I, O>, writableStrategy?: QueuingStrategy<I>, readableStrategy?: QueuingStrategy<O>): TransformStream<I, O>;
    prototype: TransformStream<any, any>;
};
import { ArrayStream } from "./writer";
export function loadStreamsPonyfill(): Promise<void>;
import { isStream } from "./util";
import { isArrayStream } from "./util";
import { isUint8Array } from "./util";
/**
 * Convert data to Stream
 * @param {ReadableStream|Uint8array|String} input  data to convert
 * @returns {ReadableStream} Converted data
 */
export function toStream(input: ReadableStream | Uint8array | string): ReadableStream;
export let toPonyfillReadable: any;
export let toNativeReadable: any;
import { concatUint8Array } from "./util";
/**
 * Concat a list of Streams
 * @param {Array<ReadableStream|Uint8array|String>} list  Array of Uint8Arrays/Strings/Streams to concatenate
 * @returns {ReadableStream} Concatenated list
 */
export function concatStream(list: Array<ReadableStream | Uint8array | string>): ReadableStream;
/**
 * Concat a list of Uint8Arrays, Strings or Streams
 * The caller should not mix Uint8Arrays with Strings, but may mix Streams with non-Streams.
 * @param {Array<Uint8array|String|ReadableStream>} Array of Uint8Arrays/Strings/Streams to concatenate
 * @returns {Uint8array|String|ReadableStream} Concatenated array
 */
export function concat(list: any): Uint8array | string | ReadableStream;
/**
 * Get a Reader
 * @param {ReadableStream|Uint8array|String} input
 * @returns {Reader}
 */
export function getReader(input: ReadableStream | Uint8array | string): Reader;
/**
 * Get a Writer
 * @param {WritableStream} input
 * @returns {Writer}
 */
export function getWriter(input: WritableStream): Writer;
/**
 * Pipe a readable stream to a writable stream. Don't throw on input stream errors, but forward them to the output stream.
 * @param {ReadableStream|Uint8array|String} input
 * @param {WritableStream} target
 * @param {Object} (optional) options
 * @returns {Promise<undefined>} Promise indicating when piping has finished (input stream closed or errored)
 * @async
 */
export function pipe(input: ReadableStream | Uint8array | string, target: WritableStream, { preventClose, preventAbort, preventCancel }?: any): Promise<undefined>;
/**
 * Pipe a readable stream through a transform stream.
 * @param {ReadableStream|Uint8array|String} input
 * @param {Object} (optional) options
 * @returns {ReadableStream} transformed stream
 */
export function transformRaw(input: ReadableStream | Uint8array | string, options: any): ReadableStream;
/**
 * Transform a stream using helper functions which are called on each chunk, and on stream close, respectively.
 * @param {ReadableStream|Uint8array|String} input
 * @param {Function} process
 * @param {Function} finish
 * @returns {ReadableStream|Uint8array|String}
 */
export function transform(input: ReadableStream | Uint8array | string, process?: Function, finish?: Function): ReadableStream | Uint8array | string;
/**
 * Transform a stream using a helper function which is passed a readable and a writable stream.
 *   This function also maintains the possibility to cancel the input stream,
 *   and does so on cancelation of the output stream, despite cancelation
 *   normally being impossible when the input stream is being read from.
 * @param {ReadableStream|Uint8array|String} input
 * @param {Function} fn
 * @returns {ReadableStream}
 */
export function transformPair(input: ReadableStream | Uint8array | string, fn: Function): ReadableStream;
/**
 * Parse a stream using a helper function which is passed a Reader.
 *   The reader additionally has a remainder() method which returns a
 *   stream pointing to the remainder of input, and is linked to input
 *   for cancelation.
 * @param {ReadableStream|Uint8array|String} input
 * @param {Function} fn
 * @returns {Any} the return value of fn()
 */
export function parse(input: ReadableStream | Uint8array | string, fn: Function): Any;
/**
 * Clone a Stream for reading it twice. The input stream can still be read after clone()ing.
 *   Reading from the clone will pull from the input stream.
 *   The input stream will only be canceled if both the clone and the input stream are canceled.
 * @param {ReadableStream|Uint8array|String} input
 * @returns {ReadableStream|Uint8array|String} cloned input
 */
export function clone(input: ReadableStream | Uint8array | string): ReadableStream | Uint8array | string;
/**
 * Clone a Stream for reading it twice. Data will arrive at the same rate as the input stream is being read.
 *   Reading from the clone will NOT pull from the input stream. Data only arrives when reading the input stream.
 *   The input stream will NOT be canceled if the clone is canceled, only if the input stream are canceled.
 *   If the input stream is canceled, the clone will be errored.
 * @param {ReadableStream|Uint8array|String} input
 * @returns {ReadableStream|Uint8array|String} cloned input
 */
export function passiveClone(input: ReadableStream | Uint8array | string): ReadableStream | Uint8array | string;
/**
 * Return a stream pointing to a part of the input stream.
 * @param {ReadableStream|Uint8array|String} input
 * @returns {ReadableStream|Uint8array|String} clone
 */
export function slice(input: ReadableStream | Uint8array | string, begin?: number, end?: number): ReadableStream | Uint8array | string;
/**
 * Read a stream to the end and return its contents, concatenated by the join function (defaults to concat).
 * @param {ReadableStream|Uint8array|String} input
 * @param {Function} join
 * @returns {Promise<Uint8array|String|Any>} the return value of join()
 * @async
 */
export function readToEnd(input: ReadableStream | Uint8array | string, join?: Function): Promise<Uint8array | string | Any>;
/**
 * Cancel a stream.
 * @param {ReadableStream|Uint8array|String} input
 * @param {Any} reason
 * @returns {Promise<Any>} indicates when the stream has been canceled
 * @async
 */
export function cancel(input: ReadableStream | Uint8array | string, reason: Any): Promise<Any>;
/**
 * Convert an async function to an ArrayStream. When the function returns, its return value is written to the stream.
 * @param {Function} fn
 * @returns {ArrayStream}
 */
export function fromAsync(fn: Function): ArrayStream;
import { nodeToWeb } from "./node-conversions";
import { webToNode } from "./node-conversions";
import { Reader } from "./reader";
import { Writer } from "./writer";
export { ArrayStream, isStream, isArrayStream, isUint8Array, concatUint8Array, nodeToWeb, webToNode };
