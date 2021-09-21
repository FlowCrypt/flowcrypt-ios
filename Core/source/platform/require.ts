/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

/// <reference path="../core/types/openpgp.d.ts" />

export const requireOpenpgp = (): typeof OpenPGP => {
  // @ts-ignore;
  if (typeof openpgp !== 'undefined') {
    // @ts-ignore;
    return openpgp; // self-contained node-mobile
  }
  // running tests on a desktop os node instance
  // making the require semi-dynamic to surpress Webpack warnings/errors. This line does not rely on webpack at all
  // if this was webpack, then the `openpgp` variable would be already set, and it would never get down here
  return require(`${'../../../source/lib/openpgp'}`); // points to flowcrypt-mobile-core/source/lib/openpgp.js
};

export const requireMimeParser = (): any => {
  // @ts-ignore;
  return global['emailjs-mime-parser'];
};

export const requireMimeBuilder = (): any => {
  // global['emailjs-mime-builder'] ?
  // dereq_emailjs_mime_builder ?
  // @ts-ignore
  return global['emailjs-mime-builder'];
};

export const requireIso88592 = (): any => {
  // @ts-ignore
  return global['iso88592'];
};
