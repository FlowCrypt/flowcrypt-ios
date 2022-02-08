export class ArrayStream extends Array<any> {
    constructor();
    getReader(): {
        read: () => Promise<{
            value: any;
            done: boolean;
        }>;
    };
    readToEnd(join: any): Promise<any>;
    clone(): ArrayStream;
    [doneWritingPromise]: any;
    [doneWritingResolve]: any;
    [doneWritingReject]: any;
    [readingIndex]: number;
}
/**
 * Check whether data is an ArrayStream
 * @param {Any} input  data to check
 * @returns {boolean}
 */
export function isArrayStream(input: Any): boolean;
/**
 * A wrapper class over the native WritableStreamDefaultWriter.
 * It also lets you "write data to" array streams instead of streams.
 * @class
 */
export function Writer(input: any): any;
export class Writer {
    /**
     * A wrapper class over the native WritableStreamDefaultWriter.
     * It also lets you "write data to" array streams instead of streams.
     * @class
     */
    constructor(input: any);
    stream: any;
    /**
     * Write a chunk of data.
     * @returns {Promise<undefined>}
     * @async
     */
    write(chunk: any): Promise<undefined>;
    /**
     * Close the stream.
     * @returns {Promise<undefined>}
     * @async
     */
    close(): Promise<undefined>;
    /**
     * Error the stream.
     * @returns {Promise<Object>}
     * @async
     */
    abort(reason: any): Promise<any>;
    /**
     * Release the writer's lock.
     * @returns {undefined}
     * @async
     */
    releaseLock(): undefined;
}
export const doneWritingPromise: unique symbol;
declare const doneWritingResolve: unique symbol;
declare const doneWritingReject: unique symbol;
declare const readingIndex: unique symbol;
export {};
