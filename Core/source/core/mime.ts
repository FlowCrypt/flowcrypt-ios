/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Dict, Str } from './common';
import { requireIso88592, requireMimeBuilder, requireMimeParser } from '../platform/require';

import { Att } from './att';
import { Buf } from './buf';
import { Catch } from '../platform/catch';
import { MimeParserNode } from './types/emailjs';
import { MsgBlock } from './msg-block';
import { MsgBlockParser } from './msg-block-parser';
import { PgpArmor } from './pgp-armor';
import { iso2022jpToUtf } from '../platform/util';

/* eslint-disable @typescript-eslint/naming-convention */
const MimeParser = requireMimeParser();
const MimeBuilder = requireMimeBuilder();
const Iso88592 = requireIso88592();
/* eslint-enable @typescript-eslint/naming-convention */

type AddressHeader = { address: string; name: string };
type MimeContentHeader = string | AddressHeader[];
export type MimeContent = {
  headers: Dict<MimeContentHeader>;
  atts: Att[];
  signature?: string;
  rawSignedContent?: string;
  subject?: string;
  html?: string;
  text?: string;
  from?: string;
  to: string[];
  cc: string[];
  bcc: string[];
};

export type MimeEncodeType = 'pgpMimeEncrypted' | 'pgpMimeSigned' | undefined;
export type RichHeaders = Dict<string | string[]>;
// eslint-disable-next-line @typescript-eslint/naming-convention
export type SendableMsgBody = { [key: string]: string | undefined; 'text/plain'?: string; 'text/html'?: string };
export type MimeProccesedMsg = {
  rawSignedContent: string | undefined;
  headers: Dict<MimeContentHeader>;
  blocks: MsgBlock[];
  from: string | undefined;
  to: string[];
};
type SendingType = 'to' | 'cc' | 'bcc';

export class Mime {
  public static processBody = (decoded: MimeContent): MsgBlock[] => {
    const blocks: MsgBlock[] = [];
    if (decoded.text) {
      const blocksFromTextPart = MsgBlockParser.detectBlocks(Str.normalize(decoded.text), true).blocks;
      // if there are some encryption-related blocks found in the text section,
      // which we can use, and not look at the html section
      if (
        blocksFromTextPart.find(b => ['pkcs7', 'encryptedMsg', 'signedMsg', 'publicKey', 'privateKey'].includes(b.type))
      ) {
        // because the html most likely containt the same thing,
        // just harder to parse pgp sections cause it's html
        blocks.push(...blocksFromTextPart);
      } else if (decoded.html) {
        // if no pgp blocks found in text part and there is html part, prefer html
        blocks.push(MsgBlock.fromContent('plainHtml', decoded.html));
      } else {
        // else if no html and just a plain text message, use that
        blocks.push(...blocksFromTextPart);
      }
    } else if (decoded.html) {
      blocks.push(MsgBlock.fromContent('plainHtml', decoded.html));
    }
    return blocks;
  };

  public static isBodyEmpty = ({ text, html }: MimeContent) => {
    return Mime.isBodyTextEmpty(text) && Mime.isBodyTextEmpty(html);
  };

  public static isBodyTextEmpty = (text: string | undefined) => {
    return !(text && !/^(\r)?(\n)?$/.test(text));
  };

  public static processAttachments = (bodyBlocks: MsgBlock[], decoded: MimeContent): MimeProccesedMsg => {
    const attachmentBlocks: MsgBlock[] = [];
    const signatureAttachments: Att[] = [];
    for (const file of decoded.atts) {
      let treatAs = file.treatAs(decoded.atts, Mime.isBodyEmpty(decoded));
      if (['needChunk', 'maybePgp'].includes(treatAs)) {
        // todo: attachments from MimeContent always have data set (so 'needChunk' should never happen),
        // and we can perform whatever analysis is needed based on the actual data,
        // but we don't want to reference MsgUtil and OpenPGP.js from this class,
        // so I suggest to move this method to MessageRenderer for further refactoring
        treatAs = 'encryptedMsg'; // publicKey?
      }
      if (treatAs === 'encryptedMsg') {
        const armored = PgpArmor.clip(file.getData().toUtfStr());
        if (armored) {
          attachmentBlocks.push(MsgBlock.fromContent('encryptedMsg', armored));
        }
      } else if (treatAs === 'signature') {
        signatureAttachments.push(file);
      } else if (treatAs === 'publicKey') {
        attachmentBlocks.push(...MsgBlockParser.detectBlocks(file.getData().toUtfStr(), true).blocks);
      } else if (treatAs === 'privateKey') {
        attachmentBlocks.push(...MsgBlockParser.detectBlocks(file.getData().toUtfStr(), true).blocks);
      } else if (treatAs === 'encryptedFile') {
        attachmentBlocks.push(
          MsgBlock.fromAtt('encryptedAtt', '', {
            name: file.name,
            type: file.type,
            length: file.getData().length,
            data: file.getData(),
            treatAs: file.treatAs(decoded.atts),
          }),
        );
      } else if (treatAs === 'plainFile') {
        attachmentBlocks.push(
          MsgBlock.fromAtt('plainAtt', '', {
            name: file.name,
            type: file.type,
            length: file.getData().length,
            data: file.getData(),
            inline: file.inline,
            cid: file.cid,
          }),
        );
      }
    }
    if (signatureAttachments.length) {
      // todo: if multiple signatures, figure out which fits what
      // attachments from MimeContent always have data set
      const signature = signatureAttachments[0].getData().toUtfStr();
      if (
        ![...bodyBlocks, ...attachmentBlocks].some(block =>
          ['plainText', 'plainHtml', 'signedMsg'].includes(block.type),
        )
      ) {
        // signed an empty message
        attachmentBlocks.push(new MsgBlock('signedMsg', '', true, signature));
      }
    }
    const blocks = [...bodyBlocks, ...attachmentBlocks];
    if (
      decoded.signature &&
      decoded.signature.includes(PgpArmor.ARMOR_HEADER_DICT.signature.begin) &&
      decoded.signature.includes(String(PgpArmor.ARMOR_HEADER_DICT.signature.end))
    ) {
      for (const block of blocks) {
        if (block.type === 'plainText') {
          block.type = 'signedMsg';
          block.signature = decoded.signature;
        } else if (block.type === 'plainHtml') {
          block.type = 'signedHtml';
          block.signature = decoded.signature;
        }
      }
      if (
        !blocks.find(
          block =>
            block.type === 'plainText' ||
            block.type === 'plainHtml' ||
            block.type === 'signedMsg' ||
            block.type === 'signedHtml',
        )
      ) {
        // signed an empty message
        blocks.push(new MsgBlock('signedMsg', '', true, decoded.signature));
      }
    }
    return {
      headers: decoded.headers,
      blocks,
      from: decoded.from,
      to: decoded.to,
      rawSignedContent: decoded.rawSignedContent,
    };
  };

  public static processDecoded = (decoded: MimeContent): MimeProccesedMsg => {
    const blocks = Mime.processBody(decoded);
    return Mime.processAttachments(blocks, decoded);
  };

  public static process = async (mimeMsg: Uint8Array): Promise<MimeProccesedMsg> => {
    const decoded = await Mime.decode(mimeMsg);
    return Mime.processDecoded(decoded);
  };

  public static isPlainImgAtt = (b: MsgBlock) => {
    return (
      b.type === 'plainAtt' &&
      b.attMeta &&
      b.attMeta.type &&
      ['image/jpeg', 'image/jpg', 'image/bmp', 'image/png', 'image/svg+xml'].includes(b.attMeta.type)
    );
  };

  public static replyHeaders = (parsedMimeMsg: MimeContent) => {
    const msgId = String(parsedMimeMsg.headers['message-id'] || '');
    const refs = String(parsedMimeMsg.headers['in-reply-to'] || '');
    // eslint-disable-next-line @typescript-eslint/naming-convention
    return { 'in-reply-to': msgId, references: refs + ' ' + msgId };
  };

  public static resemblesMsg = (msg: Uint8Array) => {
    const utf8 = new Buf(msg.slice(0, 1000)).toUtfStr().toLowerCase();
    const contentType = utf8.match(/content-type: +[0-9a-z\-\/]+/);
    if (!contentType) {
      return false;
    }
    if (
      utf8.match(/content-transfer-encoding: +[0-9a-z\-\/]+/) ||
      utf8.match(/content-disposition: +[0-9a-z\-\/]+/) ||
      utf8.match(/; boundary=/) ||
      utf8.match(/; charset=/)
    ) {
      return true;
    }
    return Boolean(contentType.index === 0 && utf8.match(/boundary=/));
  };

  public static decode = async (mimeMsg: Uint8Array): Promise<MimeContent> => {
    const mimeContent: MimeContent = {
      atts: [],
      headers: {},
      subject: undefined,
      text: undefined,
      html: undefined,
      signature: undefined,
      from: undefined,
      to: [],
      cc: [],
      bcc: [],
    };
    const parser = new MimeParser();
    const leafNodes: { [key: string]: MimeParserNode } = {};
    parser.onbody = (node: MimeParserNode) => {
      const path = String(node.path.join('.'));
      if (typeof leafNodes[path] === 'undefined') {
        leafNodes[path] = node;
      }
    };
    return await new Promise((resolve, reject) => {
      try {
        parser.onend = () => {
          try {
            for (const name of Object.keys(parser.node.headers as object)) {
              mimeContent.headers[name] = parser.node.headers[name][0].value;
            }
            mimeContent.rawSignedContent = Mime.retrieveRawSignedContent([parser.node as MimeParserNode]);
            for (const node of Object.values(leafNodes)) {
              if (Mime.getNodeType(node) === 'application/pgp-signature') {
                mimeContent.signature = node.rawContent;
              } else if (Mime.getNodeType(node) === 'text/html' && !Mime.getNodeFilename(node)) {
                // html content may be broken up into smaller pieces by attachments in between
                // AppleMail does this with inline attachments
                mimeContent.html = (mimeContent.html || '') + Mime.getNodeContentAsUtfStr(node);
              } else if (
                Mime.getNodeType(node) === 'text/plain' &&
                (!Mime.getNodeFilename(node) || Mime.isNodeInline(node))
              ) {
                mimeContent.text =
                  (mimeContent.text ? `${mimeContent.text}\n\n` : '') + Mime.getNodeContentAsUtfStr(node);
              } else if (Mime.getNodeType(node) === 'text/rfc822-headers') {
                /* eslint-disable no-underscore-dangle */
                if (node._parentNode && node._parentNode.headers.subject) {
                  mimeContent.subject = node._parentNode.headers.subject[0].value;
                }
                /* eslint-enable no-underscore-dangle */
              } else {
                mimeContent.atts.push(Mime.getNodeAsAtt(node));
              }
            }
            const headers = Mime.headerGetAddress(mimeContent, ['from', 'to', 'cc', 'bcc']);
            mimeContent.subject = String(mimeContent.subject || mimeContent.headers.subject || '');
            Object.assign(mimeContent, headers);
            resolve(mimeContent);
          } catch (e) {
            reject(e);
          }
        };
        parser.write(mimeMsg);
        parser.end();
      } catch (e) {
        // todo - on Android we may want to fail when this happens, evaluate effect on browser extension
        Catch.reportErr(e as Error);
        resolve(mimeContent);
      }
    });
  };

  public static encode = async (
    body: SendableMsgBody,
    headers: RichHeaders,
    atts: Att[] = [],
    type?: MimeEncodeType,
  ): Promise<string> => {
    const rootContentType =
      type !== 'pgpMimeEncrypted' ? 'multipart/mixed' : `multipart/encrypted; protocol="application/pgp-encrypted";`;
    const rootNode = new MimeBuilder(rootContentType, { includeBccInHeader: true });
    for (const key of Object.keys(headers)) {
      rootNode.addHeader(key, headers[key]);
    }
    if (Object.keys(body).length) {
      let contentNode: MimeParserNode;
      if (Object.keys(body).length === 1) {
        contentNode = Mime.newContentNode(
          MimeBuilder,
          Object.keys(body)[0],
          body[Object.keys(body)[0] as 'text/plain' | 'text/html'] || '',
        );
      } else {
        contentNode = new MimeBuilder('multipart/alternative');
        for (const type of Object.keys(body)) {
          // already present, that's why part of for loop
          contentNode.appendChild(Mime.newContentNode(MimeBuilder, type, body[type] ?? ''));
        }
      }
      rootNode.appendChild(contentNode);
    }
    for (const att of atts) {
      rootNode.appendChild(Mime.createAttNode(att));
    }
    return rootNode.build(); // eslint-disable-line @typescript-eslint/no-unsafe-return
  };

  public static subjectWithoutPrefixes = (subject: string): string => {
    return subject.replace(/^((Re|Fwd): ?)+/g, '').trim();
  };

  public static encodePgpMimeSigned = async (
    body: SendableMsgBody,
    headers: RichHeaders,
    atts: Att[] = [],
    sign: (data: string) => Promise<string>,
  ): Promise<string> => {
    const sigPlaceholder = `SIG_PLACEHOLDER_${Str.sloppyRandom(10)}`;
    const rootNode = new MimeBuilder(`multipart/signed; protocol="application/pgp-signature";`, {
      includeBccInHeader: true,
    });
    for (const key of Object.keys(headers)) {
      rootNode.addHeader(key, headers[key]);
    }
    const bodyNodes = new MimeBuilder('multipart/alternative');
    for (const type of Object.keys(body)) {
      bodyNodes.appendChild(Mime.newContentNode(MimeBuilder, type, body[type] ?? ''));
    }
    const signedContentNode = new MimeBuilder('multipart/mixed');
    signedContentNode.appendChild(bodyNodes);
    for (const att of atts) {
      signedContentNode.appendChild(Mime.createAttNode(att));
    }
    const sigAttPlaceholder = new Att({
      data: Buf.fromUtfStr(sigPlaceholder),
      type: 'application/pgp-signature',
      name: 'signature.asc',
    });
    const sigAttPlaceholderNode = Mime.createAttNode(sigAttPlaceholder);
    // https://tools.ietf.org/html/rfc3156#section-5 - signed content first, signature after
    rootNode.appendChild(signedContentNode);
    rootNode.appendChild(sigAttPlaceholderNode);
    const mimeStrWithPlaceholderSig = rootNode.build() as string;
    const { rawSignedContent } = await Mime.decode(Buf.fromUtfStr(mimeStrWithPlaceholderSig));
    if (!rawSignedContent) {
      console.log(`mimeStrWithPlaceholderSig(placeholder:${sigPlaceholder}):\n${mimeStrWithPlaceholderSig}`);
      throw new Error('Could not find raw signed content immediately after mime-encoding a signed message');
    }
    const realSignature = await sign(rawSignedContent);
    const pgpMimeSigned = mimeStrWithPlaceholderSig.replace(
      Buf.fromUtfStr(sigPlaceholder).toBase64Str(),
      Buf.fromUtfStr(realSignature).toBase64Str(),
    );
    if (pgpMimeSigned === mimeStrWithPlaceholderSig) {
      console.log(`pgpMimeSigned(placeholder:${sigPlaceholder}):\n${pgpMimeSigned}`);
      throw new Error('Replaced sigPlaceholder with realSignature but mime stayed the same');
    }
    return pgpMimeSigned;
  };

  private static headerGetAddress = (parsedMimeMsg: MimeContent, headersNames: Array<SendingType | 'from'>) => {
    const result: { to: string[]; cc: string[]; bcc: string[] } = { to: [], cc: [], bcc: [] };
    let from: string | undefined;
    const getHdrValAsArr = (hdr: MimeContentHeader) =>
      typeof hdr === 'string'
        ? ([hdr].map(h => Str.parseEmail(h).email).filter(e => !!e) as string[])
        : hdr.map(h => h.address);
    const getHdrValAsStr = (hdr: MimeContentHeader) =>
      Str.parseEmail((Array.isArray(hdr) ? (hdr[0] || {}).address : String(hdr || '')) || '').email;
    for (const hdrName of headersNames) {
      const header = parsedMimeMsg.headers[hdrName];
      if (header) {
        if (hdrName === 'from') {
          from = getHdrValAsStr(header);
        } else {
          result[hdrName] = [...result[hdrName], ...getHdrValAsArr(header)];
        }
      }
    }
    return { ...result, from };
  };

  private static retrieveRawSignedContent = (nodes: MimeParserNode[]): string | undefined => {
    for (const node of nodes) {
      /* eslint-disable no-underscore-dangle */
      if (!node._childNodes || !node._childNodes.length) {
        // signed nodes tend contain two children: content node, signature node.
        // If no node, then this is not pgp/mime signed content
        continue;
      }
      const isSigned = node._isMultipart === 'signed';
      const isMixedWithSig =
        node._isMultipart === 'mixed' &&
        node._childNodes.length === 2 &&
        Mime.getNodeType(node._childNodes[1]) === 'application/pgp-signature';
      if (isSigned || isMixedWithSig) {
        // PGP/MIME signed content uses <CR><LF> as in // use CR-LF https://tools.ietf.org/html/rfc3156#section-5
        // however emailjs parser will replace it to <LF>, so we fix it here
        let rawSignedContent = node._childNodes[0].raw.replace(/\r?\n/g, '\r\n');
        if (/--$/.test(rawSignedContent)) {
          // end of boundary without a mandatory newline
          rawSignedContent += '\r\n'; // emailjs wrongly leaves out the last newline, fix it here
        }
        return rawSignedContent;
      }
      return Mime.retrieveRawSignedContent(node._childNodes);
      /* eslint-enable no-underscore-dangle */
    }
    return undefined;
  };

  private static createAttNode = (att: Att): unknown => {
    // todo: MimeBuilder types
    const type = `${att.type}; name="${att.name}"`;
    const id = `f_${Str.sloppyRandom(30)}@flowcrypt`;
    const header: Dict<string> = {};
    if (att.contentDescription) {
      header['Content-Description'] = att.contentDescription;
    }
    header['Content-Disposition'] = att.inline ? 'inline' : 'attachment';
    header['X-Attachment-Id'] = id;
    header['Content-ID'] = `<${id}>`;
    header['Content-Transfer-Encoding'] = 'base64';
    return new MimeBuilder(type, { filename: att.name }).setHeader(header).setContent(att.getData());
  };

  private static getNodeType = (node: MimeParserNode, type: 'value' | 'initial' = 'value') => {
    if (node.headers['content-type'] && node.headers['content-type'][0]) {
      return node.headers['content-type'][0][type];
    }
    return undefined;
  };

  private static getNodeContentId = (node: MimeParserNode) => {
    if (node.headers['content-id'] && node.headers['content-id'][0]) {
      return node.headers['content-id'][0].value;
    }
    return undefined;
  };

  private static getNodeFilename = (node: MimeParserNode): string | undefined => {
    if (node.headers['content-disposition'] && node.headers['content-disposition'][0]) {
      const header = node.headers['content-disposition'][0];
      if (header.params && header.params.filename) {
        return String(header.params.filename);
      }
    }
    if (node.headers['content-type'] && node.headers['content-type'][0]) {
      const header = node.headers['content-type'][0];
      if (header.params && header.params.name) {
        return String(header.params.name);
      }
    }
    return;
  };

  private static isNodeInline = (node: MimeParserNode): boolean => {
    const cd = node.headers['content-disposition'];
    return cd && cd[0] && cd[0].value === 'inline';
  };

  private static fromEqualSignNotationAsBuf = (str: string): Buf => {
    return Buf.fromRawBytesStr(
      str.replace(/(=[A-F0-9]{2})+/g, equalSignUtfPart => {
        const bytes = equalSignUtfPart
          .replace(/^=/, '')
          .split('=')
          .map(twoHexDigits => parseInt(twoHexDigits, 16));
        return new Buf(bytes).toRawBytesStr();
      }),
    );
  };

  private static getNodeAsAtt = (node: MimeParserNode): Att => {
    return new Att({
      name: Mime.getNodeFilename(node),
      type: Mime.getNodeType(node),
      data:
        node.contentTransferEncoding.value === 'quoted-printable'
          ? Mime.fromEqualSignNotationAsBuf(node.rawContent ?? '')
          : node.content,
      cid: Mime.getNodeContentId(node),
    });
  };

  private static getNodeContentAsUtfStr = (node: MimeParserNode): string => {
    if (node.charset && Iso88592.labels.includes(node.charset)) {
      return Iso88592.decode(node.rawContent ?? '') as string;
    }
    let resultBuf: Buf;
    if (node.charset === 'utf-8' && node.contentTransferEncoding.value === 'base64') {
      resultBuf = Buf.fromUint8(node.content);
    } else if (node.charset === 'utf-8' && node.contentTransferEncoding.value === 'quoted-printable') {
      resultBuf = Mime.fromEqualSignNotationAsBuf(node.rawContent ?? '');
    } else {
      resultBuf = Buf.fromRawBytesStr(node.rawContent ?? '');
    }
    if (
      node.charset?.toUpperCase() === 'ISO-2022-JP' ||
      (node.charset === 'utf-8' && Mime.getNodeType(node, 'initial')?.includes('ISO-2022-JP'))
    ) {
      return iso2022jpToUtf(resultBuf);
    }
    return resultBuf.toUtfStr();
  };

  // eslint-disable-next-line @typescript-eslint/naming-convention, @typescript-eslint/no-explicit-any
  private static newContentNode = (MimeBuilder: any, type: string, content: string): MimeParserNode => {
    const node: MimeParserNode = new MimeBuilder(type).setContent(content);
    if (type === 'text/plain') {
      // gmail likes this
      node.addHeader('Content-Transfer-Encoding', 'quoted-printable');
    }
    return node;
  };
}
