/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { base64decode } from '../platform/util';

export type Dict<T> = { [key: string]: T };
export type UrlParam = string | number | null | undefined | boolean | string[];
export type UrlParams = Dict<UrlParam>;

export class Str {
  public static extractErrorMessage = (e: Error): string | undefined => {
    if (typeof e !== 'object') return undefined;
    /* eslint-disable @typescript-eslint/no-unsafe-return */
    if (typeof e.message === 'undefined') return undefined;
    if (typeof e.message === 'string') return e.message;
    /* eslint-enable @typescript-eslint/no-unsafe-return */
    return JSON.stringify(e);
  };

  public static parseEmail = (full: string, flag: 'VALIDATE' | 'DO-NOT-VALIDATE' = 'VALIDATE') => {
    let email: string | undefined;
    let name: string | undefined;
    if (full.includes('<') && full.includes('>')) {
      const openArrow = full.indexOf('<');
      const closeArrow = full.indexOf('>');
      email = full
        .substr(openArrow + 1, openArrow - closeArrow - 1)
        .replace(/["']/g, '')
        .trim()
        .toLowerCase();
      name = full.substr(0, full.indexOf('<')).replace(/["']/g, '').trim();
    } else {
      email = full.replace(/["']/g, '').trim().toLowerCase();
    }
    if (flag === 'VALIDATE' && !Str.isEmailValid(email)) {
      email = undefined;
    }
    return { email, name, full };
  };

  public static prettyPrint = (obj: unknown) => {
    return typeof obj === 'object'
      ? JSON.stringify(obj, undefined, 2).replace(/ /g, '&nbsp;').replace(/\n/g, '<br />')
      : String(obj);
  };

  public static normalizeSpaces = (str: string) => {
    return str.replace(RegExp(String.fromCharCode(160), 'g'), String.fromCharCode(32));
  };

  public static normalizeDashes = (str: string) => {
    return str.replace(/^—–|—–$/gm, '-----');
  };

  public static normalize = (str: string) => {
    return Str.normalizeSpaces(Str.normalizeDashes(str));
  };

  public static isEmailValid = (email: string) => {
    if (email.indexOf(' ') !== -1) {
      return false;
    }
    // eslint-disable-next-line max-len
    return /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/i.test(
      email,
    );
  };

  public static monthName = (monthIndex: number) => {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][monthIndex];
  };

  public static sloppyRandom = (length = 5) => {
    let id = '';
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    for (let i = 0; i < length; i++) {
      id += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return id;
  };

  public static regexEscape = (toBeUsedInRegex: string) => {
    return toBeUsedInRegex.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  };

  public static asEscapedHtml = (text: string) => {
    return text
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\//g, '&#x2F;')
      .replace(/\n/g, '<br />');
  };

  public static htmlAttrDecode = (encoded: string): unknown => {
    try {
      return JSON.parse(Str.base64urlUtfDecode(encoded));
    } catch (e) {
      return undefined;
    }
  };

  public static capitalize = (string: string): string => {
    return string
      .trim()
      .split(' ')
      .map(s => s.charAt(0).toUpperCase() + s.slice(1))
      .join(' ');
  };

  public static pluralize = (count: number, noun: string, suffix = 's'): string => {
    return `${count} ${noun}${count > 1 ? suffix : ''}`;
  };

  public static toUtcTimestamp = (datetimeStr: string, asStr = false) => {
    return asStr ? String(Date.parse(datetimeStr)) : Date.parse(datetimeStr);
  };

  public static datetimeToDate = (date: string) => {
    return date.substring(0, 10).replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;');
  };

  public static fromDate = (date: Date) => {
    return date
      .toISOString()
      .replace(/T/, ' ')
      .replace(/:[^:]+$/, '');
  };

  private static base64urlUtfDecode = (str: string) => {
    // eslint-disable-next-line max-len
    // https://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
    if (typeof str === 'undefined') {
      return str;
    }
    return decodeURIComponent(
      String(
        Array.prototype.map
          .call(base64decode(str.replace(/-/g, '+').replace(/_/g, '/')), (c: string) => {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
          })
          .join(''),
      ),
    );
  };
}

export class Value {
  public static arr = {
    unique: <T>(array: T[]): T[] => {
      const unique: T[] = [];
      for (const v of array) {
        if (!unique.includes(v)) {
          unique.push(v);
        }
      }
      return unique;
    },
    contains: <T>(arr: T[] | string, value: T): boolean => {
      return Boolean(arr && typeof arr.indexOf === 'function' && (arr as T[]).indexOf(value) !== -1);
    },
    sum: (arr: number[]) => arr.reduce((a, b) => a + b, 0),
    average: (arr: number[]) => Value.arr.sum(arr) / arr.length,
  };

  public static obj = {
    keyByValue: <T>(obj: Dict<T>, v: T) => {
      for (const k of Object.keys(obj)) {
        if (obj[k] === v) {
          return k;
        }
      }
      return undefined;
    },
  };
}
