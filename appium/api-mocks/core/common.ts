/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { base64decode, base64encode } from '../platform/util.js';
import { Xss } from '../platform/xss.js';

export type Dict<T> = { [key: string]: T; };
export type UrlParam = string | number | null | undefined | boolean | string[];
export type UrlParams = Dict<UrlParam>;
export type PromiseCancellation = { cancel: boolean };

export class Str {

  // ranges are taken from https://stackoverflow.com/a/14824756
  // with the '\u0300' -> '\u0370' modification, because from '\u0300' to '\u0370' there are only punctuation marks
  // see https://www.utf8-chartable.de/unicode-utf8-table.pl
  public static readonly ltrChars = 'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0370-\u0590\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF';
  public static readonly rtlChars = '\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC';

  public static parseEmail = (full: string, flag: 'VALIDATE' | 'DO-NOT-VALIDATE' = 'VALIDATE') => {
    let email: string | undefined;
    let name: string | undefined;
    if (full.includes('<') && full.includes('>')) {
      email = full.substr(full.indexOf('<') + 1, full.indexOf('>') - full.indexOf('<') - 1).replace(/["']/g, '').trim().toLowerCase();
      name = full.substr(0, full.indexOf('<')).replace(/["']/g, '').trim();
    } else {
      email = full.replace(/["']/g, '').trim().toLowerCase();
    }
    if (flag === 'VALIDATE' && !Str.isEmailValid(email)) {
      email = undefined;
    }
    return { email, name, full };
  }

  public static getDomainFromEmailAddress = (emailAddr: string) => {
    // todo: parseEmail()?
    return emailAddr.toLowerCase().split('@')[1];
  }

  public static rmSpecialCharsKeepUtf = (str: string, mode: 'ALLOW-SOME' | 'ALLOW-NONE'): string => {
    // not a whitelist because we still want utf chars
    str = str.replace(/[@&#`();:'",<>\{\}\[\]\\\/\n\t\r]/gi, '');
    if (mode === 'ALLOW-SOME') {
      return str;
    }
    return str.replace(/[.~!$%^*=?]/gi, '');
  }

  public static prettyPrint = (obj: any) => {
    return (typeof obj === 'object') ? JSON.stringify(obj, undefined, 2).replace(/ /g, '&nbsp;').replace(/\n/g, '<br />') : String(obj);
  }

  public static normalizeSpaces = (str: string) => {
    return str.replace(RegExp(String.fromCharCode(160), 'g'), String.fromCharCode(32));
  }

  public static normalizeDashes = (str: string) => {
    return str.replace(/^—–|—–$/gm, '-----');
  }

  public static normalize = (str: string) => {
    return Str.normalizeSpaces(Str.normalizeDashes(str));
  }

  public static spaced = (longidOrFingerprint: string) => {
    return longidOrFingerprint.replace(/(.{4})/g, '$1 ').trim();
  }

  public static truncate = (text: string, length: number): string => {
    return text.length <= length ? text : text.substring(0, length) + '...';
  }

  public static isEmailValid = (email: string) => {
    if (email.indexOf(' ') !== -1) {
      return false;
    }
    // for MOCK tests, we need emails like me@domain.com:8001 to pass
    // this then makes the extension call fes.domain.com:8001 which is where the appropriate mock runs
    email = email.replace(/\:8001$/, '');
    return /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/i.test(email);
  }

  public static monthName = (monthIndex: number) => {
    return ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][monthIndex];
  }

  public static sloppyRandom = (length: number = 5) => {
    let id = '';
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    for (let i = 0; i < length; i++) {
      id += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return id;
  }

  public static regexEscape = (toBeUsedInRegex: string) => {
    return toBeUsedInRegex.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  public static escapeTextAsRenderableHtml = (text: string) => {
    const rtlRegexp = new RegExp(`^([${Str.rtlChars}].*)$`, 'gm');
    return Xss.escape(text)
      .replace(rtlRegexp, '<div dir="rtl">$1</div>') // RTL lines
      .replace(/\n/g, '<br>\n') // leave newline so that following replaces work
      .replace(/^ +/gm, spaces => spaces.replace(/ /g, '&nbsp;'))
      .replace(/\n/g, ''); // strip newlines, already have <br>
  }

  public static htmlAttrEncode = (values: Dict<any>): string => {
    return Str.base64urlUtfEncode(JSON.stringify(values));
  }

  public static htmlAttrDecode = (encoded: string): any => {
    try {
      return JSON.parse(Str.base64urlUtfDecode(encoded)); // tslint:disable-line:no-unsafe-any
    } catch (e) {
      return undefined;
    }
  }

  public static capitalize = (string: string): string => {
    return string.trim().split(' ').map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(' ');
  }

  public static pluralize = (count: number, noun: string, suffix: string = 's'): string => {
    return `${count} ${noun}${count > 1 ? suffix : ''}`;
  }

  public static toUtcTimestamp = (datetimeStr: string, asStr: boolean = false) => {
    return asStr ? String(Date.parse(datetimeStr)) : Date.parse(datetimeStr);
  }

  public static datetimeToDate = (date: string) => {
    return date.substr(0, 10).replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;');
  }

  public static fromDate = (date: Date) => {
    return date.toISOString().replace(/T/, ' ').replace(/:[^:]+$/, '');
  }

  public static mostlyRTL = (string: string): boolean => {
    const rtlCount = string.match(new RegExp('[' + Str.rtlChars + ']', 'g'))?.length || 0;
    const lrtCount = string.match(new RegExp('[' + Str.ltrChars + ']', 'g'))?.length || 0;
    return rtlCount > lrtCount;
  }

  private static base64urlUtfEncode = (str: string) => {
    // https://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
    if (typeof str === 'undefined') {
      return str;
    }
    return base64encode(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, (match, p1) => String.fromCharCode(parseInt(String(p1), 16))))
      .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  private static base64urlUtfDecode = (str: string) => {
    // https://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
    if (typeof str === 'undefined') {
      return str;
    }
    // tslint:disable-next-line:no-unsafe-any
    return decodeURIComponent(Array.prototype.map.call(base64decode(str.replace(/-/g, '+').replace(/_/g, '/')), (c: string) => {
      return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
  }

}

export class DateUtility {
  // tslint:disable-next-line:no-null-keyword
  public static asNumber = (date: number | null | undefined): number | null => {
    if (typeof date === 'number') {
      return date;
    } else if (!date) {
      return null; // tslint:disable-line:no-null-keyword
    } else {
      return new Date(date).getTime();
    }
  }
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
    withoutKey: <T>(array: T[], i: number) => array.splice(0, i).concat(array.splice(i + 1, array.length)),
    withoutVal: <T>(array: T[], withoutVal: T) => {
      const result: T[] = [];
      for (const value of array) {
        if (value !== withoutVal) {
          result.push(value);
        }
      }
      return result;
    },
    contains: <T>(arr: T[] | string, value: T): boolean => Boolean(arr && typeof arr.indexOf === 'function' && (arr as any[]).indexOf(value) !== -1),
    sum: (arr: number[]) => arr.reduce((a, b) => a + b, 0),
    average: (arr: number[]) => Value.arr.sum(arr) / arr.length,
    zeroes: (length: number): number[] => new Array(length).map(() => 0)
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

  public static int = {
    lousyRandom: (minVal: number, maxVal: number) => minVal + Math.round(Math.random() * (maxVal - minVal)),
    getFutureTimestampInMonths: (monthsToAdd: number) => new Date().getTime() + 1000 * 3600 * 24 * 30 * monthsToAdd,
    hoursAsMiliseconds: (h: number) => h * 1000 * 60 * 60,
  };

  public static noop = (): void => undefined;

}

export class Url {

  private static URL_PARAM_DICT: Dict<boolean | null> = { '___cu_true___': true, '___cu_false___': false, '___cu_null___': null }; // tslint:disable-line:no-null-keyword

  /**
   * will convert result to desired format: camelCase or snake_case, based on what was supplied in expectedKeys
   * todo - the camelCase or snake_case functionality can now be removed
   */
  public static parse = (expectedKeys: string[], parseThisUrl?: string) => {
    const url = (parseThisUrl || window.location.search.replace('?', ''));
    const valuePairs = url.split('?').pop()!.split('&'); // str.split('?') string[].length will always be >= 1
    const rawParams: Dict<string> = {};
    const rawParamNameDict: Dict<string> = {};
    for (const valuePair of valuePairs) {
      const pair = valuePair.split('=');
      rawParams[pair[0]] = pair[1];
      Url.fillPossibleUrlParamNameVariations(pair[0], rawParamNameDict);
    }
    const processedParams: UrlParams = {};
    for (const expectedKey of expectedKeys) {
      processedParams[expectedKey] = Url.findAndProcessUrlParam(expectedKey, rawParamNameDict, rawParams);
    }
    return processedParams;
  }

  public static create = (link: string, params: UrlParams) => {
    for (const key of Object.keys(params)) {
      const value = params[key];
      if (typeof value !== 'undefined') {
        const transformed = Value.obj.keyByValue(Url.URL_PARAM_DICT, value);
        link += (link.includes('?') ? '&' : '?') + encodeURIComponent(key) + '=' + encodeURIComponent(String(typeof transformed !== 'undefined' ? transformed : value));
      }
    }
    return link;
  }

  public static removeParamsFromUrl = (url: string, paramsToDelete: string[]) => {
    const urlParts = url.split('?');
    if (!urlParts[1]) { // Nothing to remove
      return url;
    }
    let queryParams = urlParts[1];
    queryParams = queryParams[queryParams.length - 1] === '#' ? queryParams.slice(0, -1) : queryParams;
    const params = new URLSearchParams(queryParams);
    for (const p of paramsToDelete) {
      params.delete(p);
    }
    return `${urlParts[0]}?${params.toString()}`;
  }

  private static snakeCaseToCamelCase = (s: string) => {
    return s.replace(/_[a-z]/g, boundary => boundary[1].toUpperCase());
  }

  private static camelCaseToSnakeCase = (s: string) => {
    return s.replace(/[a-z][A-Z]/g, boundary => `${boundary[0]}_${boundary[1].toLowerCase()}`);
  }

  private static findAndProcessUrlParam = (expectedParamName: string, rawParamNameDict: Dict<string>, rawParms: Dict<string>): UrlParam => {
    if (typeof rawParamNameDict[expectedParamName] === 'undefined') {
      return undefined; // param name not found in param name dict
    }
    const rawValue = rawParms[rawParamNameDict[expectedParamName]];
    if (typeof rawValue === 'undefined') {
      return undefined; // original param name not found in raw params
    }
    if (typeof Url.URL_PARAM_DICT[rawValue] !== 'undefined') {
      return Url.URL_PARAM_DICT[rawValue]; // raw value was converted using a value dict to get proper: true, false, undefined, null
    }
    return decodeURIComponent(rawValue);
  }

  private static fillPossibleUrlParamNameVariations = (urlParamName: string, rawParamNameDict: Dict<string>) => {
    rawParamNameDict[urlParamName] = urlParamName;
    rawParamNameDict[Url.snakeCaseToCamelCase(urlParamName)] = urlParamName;
    rawParamNameDict[Url.camelCaseToSnakeCase(urlParamName)] = urlParamName;
    const shortened = urlParamName.replace('account', 'acct').replace('message', 'msg');
    rawParamNameDict[Url.snakeCaseToCamelCase(shortened)] = urlParamName;
    rawParamNameDict[Url.camelCaseToSnakeCase(shortened)] = urlParamName;
  }

}

export const emailKeyIndex = (scope: string, key: string): string => {
  return `${scope.replace(/[^A-Za-z0-9]+/g, '').toLowerCase()}_${key}`;
};
