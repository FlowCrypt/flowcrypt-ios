/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

/// <reference path="../lib/openpgp.d.ts" />

'use strict';

import * as openpgp from 'openpgp';

export const requireOpenpgp = (): typeof OpenPGP => {
  return openpgp as any as typeof OpenPGP;
};

export const requireMimeParser = (): any => {
  // const MimeParser = (window as any)['emailjs-mime-parser']();
  // return require('../../../../../extension/lib/emailjs/emailjs-mime-parser'); // todo
  return undefined; // the above does not work, would have to import directly from npm, but we have made custom edits to the lib so not feasible now
};

export const requireMimeBuilder = (): any => {
  // const MimeBuilder = (window as any)['emailjs-mime-builder'];
  return undefined; // todo
};

export const requireIso88592 = (): any => {
  // (window as any).iso88592
  return undefined; // todo
};
