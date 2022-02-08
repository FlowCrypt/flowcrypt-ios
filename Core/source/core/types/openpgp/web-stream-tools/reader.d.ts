/**
 * A wrapper class over the native ReadableStreamDefaultReader.
 * This additionally implements pushing back data on the stream, which
 * lets us implement peeking and a host of convenience functions.
 * It also lets you read data other than streams, such as a Uint8Array.
 * @class
 */
export function Reader(input: any): void;
export class Reader {
    /**
     * A wrapper class over the native ReadableStreamDefaultReader.
     * This additionally implements pushing back data on the stream, which
     * lets us implement peeking and a host of convenience functions.
     * It also lets you read data other than streams, such as a Uint8Array.
     * @class
     */
    constructor(input: any);
    stream: any;
    _read: any;
    _releaseLock: () => void;
    _cancel: any;
    /**
     * Read a chunk of data.
     * @returns {Promise<Object>} Either { done: false, value: Uint8Array | String } or { done: true, value: undefined }
     * @async
     */
    read(): Promise<any>;
    /**
     * Allow others to read the stream.
     */
    releaseLock(): void;
    /**
     * Cancel the stream.
     */
    cancel(reason: any): any;
    /**
     * Read up to and including the first \n character.
     * @returns {Promise<String|Undefined>}
     * @async
     */
    readLine(): Promise<string | undefined>;
    /**
     * Read a single byte/character.
     * @returns {Promise<Number|String|Undefined>}
     * @async
     */
    readByte(): Promise<number | string | undefined>;
    /**
     * Read a specific amount of bytes/characters, unless the stream ends before that amount.
     * @returns {Promise<Uint8Array|String|Undefined>}
     * @async
     */
    readBytes(length: any): Promise<Uint8Array | string | undefined>;
    /**
     * Peek (look ahead) a specific amount of bytes/characters, unless the stream ends before that amount.
     * @returns {Promise<Uint8Array|String|Undefined>}
     * @async
     */
    peekBytes(length: any): Promise<Uint8Array | string | undefined>;
    /**
     * Push data to the front of the stream.
     * Data must have been read in the last call to read*.
     * @param {...(Uint8Array|String|Undefined)} values
     */
    unshift(...values: (Uint8Array | string | undefined)[]): void;
    /**
     * Read the stream to the end and return its contents, concatenated by the join function (defaults to streams.concat).
     * @param {Function} join
     * @returns {Promise<Uint8array|String|Any>} the return value of join()
     * @async
     */
    readToEnd(join?: Function): Promise<Uint8array | string | Any>;
    [externalBuffer]: any;
}
export const externalBuffer: unique symbol;
