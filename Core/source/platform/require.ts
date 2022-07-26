/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

export const requireMimeParser = (): any => {
  // @ts-ignore;
  return global['emailjs-mime-parser']; // eslint-disable-line @typescript-eslint/no-unsafe-return
};

export const requireMimeBuilder = (): any => {
  // global['emailjs-mime-builder'] ?
  // dereq_emailjs_mime_builder ?
  // @ts-ignore
  return global['emailjs-mime-builder']; // eslint-disable-line @typescript-eslint/no-unsafe-return
};

export const requireIso88592 = (): any => {
  // @ts-ignore
  return global.iso88592;
};
