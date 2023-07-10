/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

export class Catch {
  public static reportErr = (e: Error) => {
    console.error(e); // core errors that were not re-thrown are not so interesting as of 2018
  };

  public static report = (name: string, details?: unknown) => {
    console.error(name, details); // core reports are not so interesting as of 2018
  };

  public static undefinedOnException = async <T>(p: Promise<T>): Promise<T | undefined> => {
    try {
      return await p;
    } catch (e) {
      return undefined;
    }
  };
}
