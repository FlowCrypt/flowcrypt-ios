/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { MsgBlock, MsgBlockType } from '../core/msg-block';

import { Buf } from '../core/buf';
import { Mime } from '../core/mime';
import { Str } from '../core/common';
import { Xss } from '../platform/xss';
import { VerifyRes } from '../core/pgp-msg';

export type Buffers = (Buf | Uint8Array)[];
export type EndpointRes = { json: Record<string, unknown>; data: Buf | Uint8Array };

export const isContentBlock = (t: MsgBlockType) => {
  return (
    t === 'plainText' ||
    t === 'decryptedText' ||
    t === 'plainHtml' ||
    t === 'decryptedHtml' ||
    t === 'signedMsg' ||
    t === 'verifiedMsg'
  );
};

const seamlessLockBg =
  'iVBORw0KGgoAAAANSUhEUgAAAFoAAABaCAMAAAAPdrEwAAAAh1BMVEXw8PD////' +
  'w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8' +
  'PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PD' +
  '7MuHIAAAALXRSTlMAAAECBAcICw4QEhUZIyYqMTtGTV5kdn2Ii5mfoKOqrbG0uL6/' +
  'xcnM0NTX2t1l7cN4AAAB0UlEQVR4Ae3Y3Y4SQRCG4bdHweFHRBTBH1FRFLXv//qsA' +
  '8kmvbMdXhh2Q0KfknpSCQc130c67s22+e9+v/+d84fxkSPH0m/' +
  '+5P9vN7vRV0vPfx7or1NB23e99KAHuoXOOc6moQsBwNN1Q9g4Wdh1uq3MA7Qn0+2ylAt7WbWpyT' +
  '+Wo8roKH6v2QhZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2gjZ2AUNOLmwg' +
  'QdogEJ2dnF3UJdU3WjqO/u96aYtVd/7jqvIyu76G5se6GaY7tNNcy5d7se7eWVnDz87fMkuVuS8' +
  'epF6f9NPObPY5re9y4N1/vya9Gr3se2bfvl9M0mkyZdv077p+a/' +
  '3z4Meby5Br4NWiV51BaiUqfLro9I3WiR61RVcffwfXI7u5zZ20EOA82Uu8x3SlrSwXQuBSvSqK0' +
  'AletUVoBK96gpIwlZy0MJWctDCVnLQwlZy0MJWctDCVnLQwlZy0MJWctDCVnLQwlZy0MJWctDCV' +
  'nLQwlZy0MJWckIletUVIJJxITN6wtZd2EI+0NquyIJOnUpFVvRpcwmV6FVXgEr0qitAJXrVFaAS' +
  'veoKUIledQWoRK+6AlSiV13BP+/VVbky7Xq1AAAAAElFTkSuQmCC';

const fmtMsgContentBlockAsHtml = (dirtyContent: string, frameColor: 'green' | 'gray' | 'red' | 'plain') => {
  const generalCss =
    'background: white;padding-left: 8px;min-height: 50px;padding-top: 4px;' + 'padding-bottom: 4px;width: 100%;';
  let frameCss: string;
  if (frameColor === 'green') {
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #31A217;border-right: none;' +
      'background-image: url(data:image/png;base64,${seamlessLockBg});`;
  } else if (frameColor === 'red') {
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #d14836;border-right: none;`;
  } else if (frameColor === 'plain') {
    frameCss = `border: none;`;
  } else {
    // gray
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #989898;border-right: none;`;
  }
  return (
    `<div class="MsgBlock ${frameColor}" style="${generalCss}${frameCss}">` +
    `${Xss.htmlSanitizeKeepBasicTags(dirtyContent)}</div><!-- next MsgBlock -->\n`
  );
};

export const stripHtmlRootTags = (html: string) => {
  // todo - this is very rudimentary, use a proper parser
  html = html.replace(/<\/?html[^>]*>/g, ''); // remove opening and closing html tags
  html = html.replace(/<head[^>]*>.*<\/head>/g, ''); // remove the whole head section
  html = html.replace(/<\/?body[^>]*>/g, ''); // remove opening and closing body tags
  return html.trim();
};

/**
 * replace content of imgs: <img src="cid:16c7a8c3c6a8d4ab1e01">
 */
const fillInlineHtmlImgs = (htmlContent: string, inlineImgsByCid: { [cid: string]: MsgBlock }): string => {
  return htmlContent.replace(/src="cid:([^"]+)"/g, (originalSrcAttr, cid) => {
    const img = inlineImgsByCid[cid];
    if (img) {
      // in current usage, as used by `endpoints.ts`: `block.attMeta!.data`
      // actually contains base64 encoded data, not Uint8Array as the type claims
      const alteredSrcAttr = `src="data:${img.attMeta?.type};base64,${img.attMeta?.data}"`;
      // delete to find out if any imgs were unused
      // later we can add the unused ones at the bottom
      // (though as implemented will cause issues if the same cid is reused
      // in several places in html - which is theoretically valid - only first will get replaced)
      delete inlineImgsByCid[cid];
      return alteredSrcAttr;
    } else {
      return originalSrcAttr;
    }
  });
};

export const fmtContentBlock = (allContentBlocks: MsgBlock[]): { contentBlock: MsgBlock; text: string } => {
  const msgContentAsHtml: string[] = [];
  const msgContentAsText: string[] = [];
  const contentBlocks = allContentBlocks.filter(b => !Mime.isPlainImgAtt(b));
  const imgsAtTheBottom: MsgBlock[] = [];
  const inlineImgsByCid: { [cid: string]: MsgBlock } = {};
  for (const plainImgBlock of allContentBlocks.filter(b => Mime.isPlainImgAtt(b))) {
    if (plainImgBlock.attMeta?.cid) {
      inlineImgsByCid[plainImgBlock.attMeta.cid.replace(/>$/, '').replace(/^</, '')] = plainImgBlock;
    } else {
      imgsAtTheBottom.push(plainImgBlock);
    }
  }

  let verifyRes: VerifyRes | undefined;
  let mixedSignatures = false;
  let signedBlockCount = 0;
  for (const block of contentBlocks) {
    if (block.verifyRes) {
      ++signedBlockCount;
      if (!verifyRes) {
        verifyRes = block.verifyRes;
      } else if (!block.verifyRes.match) {
        if (verifyRes.match) {
          verifyRes = block.verifyRes;
        }
      } else if (verifyRes.match && block.verifyRes.signer !== verifyRes.signer) {
        mixedSignatures = true;
      }
    }
    if (block.type === 'decryptedText') {
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(Str.asEscapedHtml(block.content.toString()), 'green'));
      msgContentAsText.push(block.content.toString() + '\n');
    } else if (block.type === 'decryptedHtml') {
      // todo - add support for inline imgs? when included using cid
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(stripHtmlRootTags(block.content.toString()), 'green'));
      msgContentAsText.push(Xss.htmlUnescape(Xss.htmlSanitizeAndStripAllTags(block.content.toString(), '\n') + '\n'));
    } else if (block.type === 'plainText') {
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(Str.asEscapedHtml(block.content.toString()), 'plain'));
      msgContentAsText.push(block.content.toString() + '\n');
    } else if (block.type === 'plainHtml') {
      const dirtyHtmlWithImgs = fillInlineHtmlImgs(stripHtmlRootTags(block.content.toString()), inlineImgsByCid);
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(dirtyHtmlWithImgs, 'plain'));
      msgContentAsText.push(Xss.htmlUnescape(Xss.htmlSanitizeAndStripAllTags(dirtyHtmlWithImgs, '\n') + '\n'));
    } else if (block.type === 'verifiedMsg') {
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(block.content.toString(), 'gray'));
      msgContentAsText.push(Xss.htmlSanitizeAndStripAllTags(block.content.toString(), '\n') + '\n');
    } else {
      msgContentAsHtml.push(fmtMsgContentBlockAsHtml(block.content.toString(), 'plain'));
      msgContentAsText.push(block.content.toString() + '\n');
    }
  }

  if (verifyRes && verifyRes.match) {
    if (mixedSignatures) {
      verifyRes.mixed = true;
    }
    if (signedBlockCount > 0 && signedBlockCount !== contentBlocks.length) {
      verifyRes.partial = true;
    }
  }

  for (const inlineImg of imgsAtTheBottom.concat(Object.values(inlineImgsByCid))) {
    // render any images we did not insert into content, at the bottom
    const alt = `${inlineImg.attMeta?.name || '(unnamed image)'} - ${inlineImg.attMeta?.length ?? 0 / 1024}kb`;
    // in current usage, as used by `endpoints.ts`: `block.attMeta!.data`
    // actually contains base64 encoded data, not Uint8Array as the type claims
    const inlineImgTag =
      `<img src="data:${inlineImg.attMeta?.type};` + `base64,${inlineImg.attMeta?.data}" alt="${Xss.escape(alt)} " />`;
    msgContentAsHtml.push(fmtMsgContentBlockAsHtml(inlineImgTag, 'plain'));
    msgContentAsText.push(`[image: ${alt}]\n`);
  }

  const contentBlock = MsgBlock.fromContent(
    'plainHtml',
    `
    <!DOCTYPE html><html>
      <head>
        <meta name="viewport" content="width=device-width" />
        <style>
          body { word-wrap: break-word; word-break: break-word; hyphens: auto; margin-left: 0px; padding-left: 0px; }
          body img { display: inline !important; height: auto !important; max-width: 95% !important; }
          body pre { white-space: pre-wrap !important; }
          body > div.MsgBlock > table { zoom: 75% } /* table layouts tend to overflow - eg emails from fb */
        </style>
      </head>
      <body>${msgContentAsHtml.join('')}</body>
    </html>`,
  );
  contentBlock.verifyRes = verifyRes;
  return { contentBlock, text: msgContentAsText.join('').trim() };
};

// eslint-disable-next-line @typescript-eslint/ban-types
export const fmtRes = (response: {}, data?: Buf | Uint8Array): EndpointRes => {
  return {
    json: response,
    data: data || new Uint8Array(0),
  };
};

export const fmtErr = (e: Error): EndpointRes => {
  return fmtRes({
    error: {
      message: String(e),
      stack: e && typeof e === 'object' ? e.stack || '' : '',
    },
  });
};

export const removeUndefinedValues = (object: object) => {
  for (const objectKey in object) {
    if (object[objectKey as keyof object] === undefined) {
      delete object[objectKey as keyof object];
    }
  }
};
