export const isNode: boolean;
/**
 * Check whether data is a Stream, and if so of which type
 * @param {Any} input  data to check
 * @returns {'web'|'ponyfill'|'node'|'array'|'web-like'|false}
 */
export function isStream(input: Any): 'web' | 'ponyfill' | 'node' | 'array' | 'web-like' | false;
import { isArrayStream } from "./writer";
/**
 * Check whether data is a Uint8Array
 * @param {Any} input  data to check
 * @returns {Boolean}
 */
export function isUint8Array(input: Any): boolean;
/**
 * Concat Uint8Arrays
 * @param {Array<Uint8array>} Array of Uint8Arrays to concatenate
 * @returns {Uint8array} Concatenated array
 */
export function concatUint8Array(arrays: any): Uint8array;
export { isArrayStream };
