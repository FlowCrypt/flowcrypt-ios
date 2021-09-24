/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

export class Catch {

  public static reportErr = (e: any) => {
    console.error(e); // core errors that were not re-thrown are not so interesting as of 2018
  }

  public static report = (name: string, details?: any) => {
    console.error(name, details); // core reports are not so interesting as of 2018
  }

}
