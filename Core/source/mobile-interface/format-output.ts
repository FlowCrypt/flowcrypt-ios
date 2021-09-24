/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { MsgBlock, MsgBlockType } from '../core/msg-block';

import { Buf } from '../core/buf';
import { Mime } from '../core/mime';
import { Str } from '../core/common';
import { Xss } from '../platform/xss';

export type Buffers = (Buf | Uint8Array)[];

export const isContentBlock = (t: MsgBlockType) => t === 'plainText' || t === 'decryptedText' || t === 'plainHtml' || t === 'decryptedHtml' || t === 'signedMsg' || t === 'verifiedMsg';

const seamlessLockBg = 'iVBORw0KGgoAAAANSUhEUgAAAFoAAABaCAMAAAAPdrEwAAAAh1BMVEXw8PD////w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PD7MuHIAAAALXRSTlMAAAECBAcICw4QEhUZIyYqMTtGTV5kdn2Ii5mfoKOqrbG0uL6/xcnM0NTX2t1l7cN4AAAB0UlEQVR4Ae3Y3Y4SQRCG4bdHweFHRBTBH1FRFLXv//qsA8kmvbMdXhh2Q0KfknpSCQc130c67s22+e9+v/+d84fxkSPH0m/+5P9vN7vRV0vPfx7or1NB23e99KAHuoXOOc6moQsBwNN1Q9g4Wdh1uq3MA7Qn0+2ylAt7WbWpyT+Wo8roKH6v2QhZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2ghZ2gjZ2AUNOLmwgQdogEJ2dnF3UJdU3WjqO/u96aYtVd/7jqvIyu76G5se6GaY7tNNcy5d7se7eWVnDz87fMkuVuS8epF6f9NPObPY5re9y4N1/vya9Gr3se2bfvl9M0mkyZdv077p+a/3z4Meby5Br4NWiV51BaiUqfLro9I3WiR61RVcffwfXI7u5zZ20EOA82Uu8x3SlrSwXQuBSvSqK0AletUVoBK96gpIwlZy0MJWctDCVnLQwlZy0MJWctDCVnLQwlZy0MJWctDCVnLQwlZy0MJWctDCVnLQwlZy0MJWckIletUVIJJxITN6wtZd2EI+0NquyIJOnUpFVvRpcwmV6FVXgEr0qitAJXrVFaASveoKUIledQWoRK+6AlSiV13BP+/VVbky7Xq1AAAAAElFTkSuQmCC';

const fmtMsgContentBlockAsHtml = (dirtyContent: string, frameColor: 'green' | 'gray' | 'red' | 'plain') => {
  const generalCss = `background: white;padding-left: 8px;min-height: 50px;padding-top: 4px;padding-bottom: 4px;width: 100%;`;
  let frameCss: string;
  if (frameColor === 'green') {
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #31A217;border-right: none;background-image: url(data:image/png;base64,${seamlessLockBg});`;
  } else if (frameColor === 'red') {
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #d14836;border-right: none;`;
  } else if (frameColor === 'plain') {
    frameCss = `border: none;`;
  } else { // gray
    frameCss = `border: 1px solid #f0f0f0;border-left: 8px solid #989898;border-right: none;`;
  }
  return `<div class="MsgBlock ${frameColor}" style="${generalCss}${frameCss}">${Xss.htmlSanitizeKeepBasicTags(dirtyContent)}</div><!-- next MsgBlock -->\n`;
}

export const stripHtmlRootTags = (html: string) => { // todo - this is very rudimentary, use a proper parser
  html = html.replace(/<\/?html[^>]*>/g, ''); // remove opening and closing html tags
  html = html.replace(/<head[^>]*>.*<\/head>/g, '') // remove the whole head section
  html = html.replace(/<\/?body[^>]*>/g, ''); // remove opening and closing body tags
  return html.trim();
}

/**
 * replace content of imgs: <img src="cid:16c7a8c3c6a8d4ab1e01">
 */
const fillInlineHtmlImgs = (htmlContent: string, inlineImgsByCid: { [cid: string]: MsgBlock }): string => {
  return htmlContent.replace(/src="cid:([^"]+)"/g, (originalSrcAttr, cid) => {
    const img = inlineImgsByCid[cid];
    if (img) {
      // in current usage, as used by `endpoints.ts`: `block.attMeta!.data` actually contains base64 encoded data, not Uint8Array as the type claims
      let alteredSrcAttr = `src="data:${img.attMeta!.type};base64,${img.attMeta!.data}"`;
      // delete to find out if any imgs were unused
      // later we can add the unused ones at the bottom 
      // (though as implemented will cause issues if the same cid is reused in several places in html - which is theoretically valid - only first will get replaced)
      delete inlineImgsByCid[cid];
      return alteredSrcAttr;
    } else {
      return originalSrcAttr;
    }
  });
}

export const fmtContentBlock = (allContentBlocks: MsgBlock[]): { contentBlock: MsgBlock, text: string } => {
  let msgContentAsHtml = '';
  let msgContentAsText = '';
  const contentBlocks = allContentBlocks.filter(b => !Mime.isPlainImgAtt(b))
  const imgsAtTheBottom: MsgBlock[] = [];
  const inlineImgsByCid: { [cid: string]: MsgBlock } = {};
  for (let plainImgBlock of allContentBlocks.filter(b => Mime.isPlainImgAtt(b))) {
    if (plainImgBlock.attMeta!.cid) {
      inlineImgsByCid[plainImgBlock.attMeta!.cid.replace(/>$/, '').replace(/^</, '')] = plainImgBlock;
    } else {
      imgsAtTheBottom.push(plainImgBlock);
    }
  }
  for (const block of contentBlocks) {
    if (block.type === 'decryptedText') {
      msgContentAsHtml += fmtMsgContentBlockAsHtml(Str.asEscapedHtml(block.content.toString()), 'green');
      msgContentAsText += block.content.toString() + '\n';
    } else if (block.type === 'decryptedHtml') {
      // todo - add support for inline imgs? when included using cid
      msgContentAsHtml += fmtMsgContentBlockAsHtml(stripHtmlRootTags(block.content.toString()), 'green');
      msgContentAsText += Xss.htmlUnescape(Xss.htmlSanitizeAndStripAllTags(block.content.toString(), '\n') + '\n');
    } else if (block.type === 'plainText') {
      msgContentAsHtml += fmtMsgContentBlockAsHtml(Str.asEscapedHtml(block.content.toString()), 'plain');
      msgContentAsText += block.content.toString() + '\n';
    } else if (block.type === 'plainHtml') {
      const dirtyHtmlWithImgs = fillInlineHtmlImgs(stripHtmlRootTags(block.content.toString()), inlineImgsByCid);
      msgContentAsHtml += fmtMsgContentBlockAsHtml(dirtyHtmlWithImgs, 'plain');
      msgContentAsText += Xss.htmlUnescape(Xss.htmlSanitizeAndStripAllTags(dirtyHtmlWithImgs, '\n') + '\n');
    } else if (block.type === 'verifiedMsg') {
      msgContentAsHtml += fmtMsgContentBlockAsHtml(block.content.toString(), 'gray');
      msgContentAsText += Xss.htmlSanitizeAndStripAllTags(block.content.toString(), '\n') + '\n';
    } else {
      msgContentAsHtml += fmtMsgContentBlockAsHtml(block.content.toString(), 'plain');
      msgContentAsText += block.content.toString() + '\n';
    }
  }
  for (const inlineImg of imgsAtTheBottom.concat(Object.values(inlineImgsByCid))) { // render any images we did not insert into content, at the bottom
    let alt = `${inlineImg.attMeta!.name || '(unnamed image)'} - ${inlineImg.attMeta!.length! / 1024}kb`;
    // in current usage, as used by `endpoints.ts`: `block.attMeta!.data` actually contains base64 encoded data, not Uint8Array as the type claims
    let inlineImgTag = `<img src="data:${inlineImg.attMeta!.type};base64,${inlineImg.attMeta!.data}" alt="${Xss.escape(alt)} " />`;
    msgContentAsHtml += fmtMsgContentBlockAsHtml(inlineImgTag, 'plain');
    msgContentAsText += `[image: ${alt}]\n`;
  }
  msgContentAsHtml = `
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
    <body>${msgContentAsHtml}</body>
  </html>`;
  return { contentBlock: MsgBlock.fromContent('plainHtml', msgContentAsHtml), text: msgContentAsText.trim() };
}

export const fmtRes = (response: {}, data?: Buf | Uint8Array): Buffers => {
  const buffers: Buffers = [];
  buffers.push(Buf.fromUtfStr(JSON.stringify(response)));
  buffers.push(Buf.fromUtfStr('\n'));
  if (data) {
    buffers.push(data);
  }
  return buffers;
}

export const fmtErr = (e: any): Buf => Buf.concat(fmtRes({
  error: {
    message: String(e),
    stack: e && typeof e === 'object' ? e.stack || '' : ''
  }
}));

export const printReplayTestDefinition = (endpoint: string, request: {}, data: Buf) => {
  console.log(`
ava.test.only('replaying', async t => {
  const reqData = Buf.fromBase64Str('${Buf.fromUint8(data).toBase64Str()}');
  console.log('replay ${endpoint}: ', ${JSON.stringify(request)}, '-------- begin req data ---------', reqData.toString(), '--------- end req data ---------');
  const { data, json } = await request('${endpoint}', ${JSON.stringify(request)}, Buffer.from(reqData));
  console.log('response: ', json, '\n\n\n-------- begin res data ---------', Buf.fromUint8(data).toString(), '--------- end res data ---------\n\n\n');
  t.pass();
});
  `)
}
