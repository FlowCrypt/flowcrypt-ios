/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import { Dict, Str } from './common.js';
import { requireIso88592, requireMimeBuilder, requireMimeParser } from '../platform/require.js';

import { Attachment } from './attachment.js';
import { Buf } from './buf.js';
import { Catch } from '../platform/catch.js';
import { MimeParserNode } from './types/emailjs';
import { MsgBlock } from './msg-block.js';
import { MsgBlockParser } from './msg-block-parser.js';
import { PgpArmor } from './crypto/pgp/pgp-armor.js';
import { iso2022jpToUtf } from '../platform/util.js';

const MimeParser = requireMimeParser();  // tslint:disable-line:variable-name
const MimeBuilder = requireMimeBuilder();  // tslint:disable-line:variable-name
const Iso88592 = requireIso88592();  // tslint:disable-line:variable-name

type AddressHeader = { address: string; name: string; };
type MimeContentHeader = string | AddressHeader[];
export type MimeContent = {
  headers: Dict<MimeContentHeader>;
  attachments: Attachment[];
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

export type MimeEncodeType = 'pgpMimeEncrypted' | 'pgpMimeSigned' | 'smimeEncrypted' | 'smimeSigned' | undefined;
export type RichHeaders = Dict<string | string[]>;
export type SendableMsgBody = {
  [key: string]: string | Buf | undefined;
  'text/plain'?: string;
  'text/html'?: string;
  'pkcs7/buf'?: Buf; // DER-encoded PKCS#7 message
};
export type MimeProccesedMsg = {
  rawSignedContent: string | undefined,
  headers: Dict<MimeContentHeader>,
  blocks: MsgBlock[],
  from: string | undefined,
  to: string[]
};
type SendingType = 'to' | 'cc' | 'bcc';

export class Mime {

  public static processDecoded = (decoded: MimeContent): MimeProccesedMsg => {
    const blocks: MsgBlock[] = [];
    if (decoded.text) {
      const blocksFromTextPart = MsgBlockParser.detectBlocks(Str.normalize(decoded.text)).blocks;
      // if there are some encryption-related blocks found in the text section, which we can use, and not look at the html section
      if (blocksFromTextPart.find(b => ['pkcs7', 'encryptedMsg', 'signedMsg', 'publicKey', 'privateKey'].includes(b.type))) {
        blocks.push(...blocksFromTextPart); // because the html most likely containt the same thing, just harder to parse pgp sections cause it's html
      } else if (decoded.html) { // if no pgp blocks found in text part and there is html part, prefer html
        blocks.push(MsgBlock.fromContent('plainHtml', decoded.html));
      } else { // else if no html and just a plain text message, use that
        blocks.push(...blocksFromTextPart);
      }
    } else if (decoded.html) {
      blocks.push(MsgBlock.fromContent('plainHtml', decoded.html));
    }
    for (const file of decoded.attachments) {
      const treatAs = file.treatAs();
      if (treatAs === 'encryptedMsg') {
        const armored = PgpArmor.clip(file.getData().toUtfStr());
        if (armored) {
          blocks.push(MsgBlock.fromContent('encryptedMsg', armored));
        }
      } else if (treatAs === 'signature') {
        decoded.signature = decoded.signature || file.getData().toUtfStr();
      } else if (treatAs === 'publicKey') {
        blocks.push(...MsgBlockParser.detectBlocks(file.getData().toUtfStr()).blocks);
      } else if (treatAs === 'privateKey') {
        blocks.push(...MsgBlockParser.detectBlocks(file.getData().toUtfStr()).blocks);
      } else if (treatAs === 'encryptedFile') {
        blocks.push(MsgBlock.fromAttachment('encryptedAttachment', '', { name: file.name, type: file.type, length: file.getData().length, data: file.getData() }));
      } else if (treatAs === 'plainFile') {
        blocks.push(MsgBlock.fromAttachment('plainAttachment', '', {
          name: file.name, type: file.type, length: file.getData().length, data: file.getData(), inline: file.inline, cid: file.cid
        }));
      }
    }
    if (decoded.signature) {
      for (const block of blocks) {
        if (block.type === 'plainText') {
          block.type = 'signedText';
          block.signature = decoded.signature;
        } else if (block.type === 'plainHtml') {
          block.type = 'signedHtml';
          block.signature = decoded.signature;
        }
      }
      if (!blocks.find(block => ['plainText', 'plainHtml', 'signedMsg', 'signedHtml', 'signedText'].includes(block.type))) { // signed an empty message
        blocks.push(new MsgBlock("signedMsg", "", true, decoded.signature));
      }
    }
    return { headers: decoded.headers, blocks, from: decoded.from, to: decoded.to, rawSignedContent: decoded.rawSignedContent };
  }

  public static process = async (mimeMsg: Uint8Array): Promise<MimeProccesedMsg> => {
    const decoded = await Mime.decode(mimeMsg);
    return Mime.processDecoded(decoded);
  }

  public static isPlainImgAttachment = (b: MsgBlock) => {
    return b.type === 'plainAttachment' && b.attachmentMeta && b.attachmentMeta.type && ['image/jpeg', 'image/jpg',
      'image/bmp', 'image/png', 'image/svg+xml'].includes(b.attachmentMeta.type);
  }

  public static replyHeaders = (parsedMimeMsg: MimeContent) => {
    const msgId = String(parsedMimeMsg.headers['message-id'] || '');
    const refs = String(parsedMimeMsg.headers['in-reply-to'] || '');
    return { 'in-reply-to': msgId, 'references': refs + ' ' + msgId };
  }

  public static resemblesMsg = (msg: Uint8Array) => {
    const chunk = new Buf(msg.slice(0, 3000)).toUtfStr().toLowerCase().replace(/\r\n/g, '\n');
    const headers = chunk.split('\n\n')[0];
    if (!headers) {
      return false;
    }
    const contentType = headers.match(/content-type: +[0-9a-z\-\/]+/);
    if (!contentType) {
      return false;
    }
    if (headers.match(/;\s+boundary=/) || headers.match(/;\s+charset=/)) {
      return true;
    }
    if (!headers.match(/boundary=/)) {
      return false;
    }
    if (chunk.match(/\ncontent-transfer-encoding: +[0-9a-z\-\/]+/) || chunk.match(/\ncontent-disposition: +[0-9a-z\-\/]+/)) {
      return true; // these tend to be inside body-part headers, after the first `\n\n` which we test above
    }
    return contentType.index === 0;
  }

  public static decode = async (mimeMsg: Uint8Array): Promise<MimeContent> => {
    let mimeContent: MimeContent = { attachments: [], headers: {}, subject: undefined, text: undefined, html: undefined, signature: undefined, from: undefined, to: [], cc: [], bcc: [] };
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
        parser.onend = async () => {
          try {
            for (const name of Object.keys(parser.node.headers)) {
              mimeContent.headers[name] = parser.node.headers[name][0].value;
            }
            mimeContent.rawSignedContent = Mime.retrieveRawSignedContent([parser.node]);
            if (!mimeContent.subject && mimeContent.rawSignedContent) {
              const rawSignedContentDecoded = await Mime.decode(Buf.fromUtfStr(mimeContent.rawSignedContent));
              mimeContent.subject = rawSignedContentDecoded.subject;
            }
            for (const node of Object.values(leafNodes)) {
              if (Mime.getNodeType(node) === 'application/pgp-signature') {
                mimeContent.signature = node.rawContent;
              } else if (Mime.getNodeType(node) === 'text/html' && !Mime.getNodeFilename(node)) {
                // html content may be broken up into smaller pieces by attachments in between
                // AppleMail does this with inline attachments
                mimeContent.html = (mimeContent.html || '') + Mime.getNodeContentAsUtfStr(node);
              } else if (Mime.getNodeType(node) === 'text/plain' && (!Mime.getNodeFilename(node) || Mime.isNodeInline(node))) {
                mimeContent.text = (mimeContent.text ? `${mimeContent.text}\n\n` : '') + Mime.getNodeContentAsUtfStr(node);
              } else if (Mime.getNodeType(node) === 'text/rfc822-headers') {
                if (node._parentNode && node._parentNode.headers.subject) {
                  mimeContent.subject = node._parentNode.headers.subject[0].value;
                }
              } else {
                mimeContent.attachments.push(Mime.getNodeAsAttachment(node));
              }
            }
            const headers = Mime.headerGetAddress(mimeContent, ['from', 'to', 'cc', 'bcc']);
            mimeContent.subject = String(mimeContent.subject || mimeContent.headers.subject || '');
            mimeContent = Object.assign(mimeContent, headers);
            resolve(mimeContent);
          } catch (e) {
            reject(e);
          }
        };
        parser.write(mimeMsg);
        parser.end();
      } catch (e) { // todo - on Android we may want to fail when this happens, evaluate effect on browser extension
        Catch.reportErr(e);
        resolve(mimeContent);
      }
    });
  }

  public static encode = async (body: SendableMsgBody, headers: RichHeaders, attachments: Attachment[] = [], type?: MimeEncodeType): Promise<string> => {
    const rootContentType = type !== 'pgpMimeEncrypted' ? 'multipart/mixed' : `multipart/encrypted; protocol="application/pgp-encrypted";`;
    const rootNode = new MimeBuilder(rootContentType, { includeBccInHeader: true }); // tslint:disable-line:no-unsafe-any
    for (const key of Object.keys(headers)) {
      rootNode.addHeader(key, headers[key]); // tslint:disable-line:no-unsafe-any
    }
    if (Object.keys(body).length) {
      let contentNode: MimeParserNode;
      if (Object.keys(body).length === 1) {
        contentNode = Mime.newContentNode(MimeBuilder, Object.keys(body)[0], body[Object.keys(body)[0] as "text/plain" | "text/html"] || '');
      } else {
        contentNode = new MimeBuilder('multipart/alternative'); // tslint:disable-line:no-unsafe-any
        for (const type of Object.keys(body)) {
          contentNode.appendChild(Mime.newContentNode(MimeBuilder, type, body[type]!.toString())); // already present, that's why part of for loop
        }
      }
      rootNode.appendChild(contentNode); // tslint:disable-line:no-unsafe-any
    }
    for (const attachment of attachments) {
      rootNode.appendChild(Mime.createAttachmentNode(attachment)); // tslint:disable-line:no-unsafe-any
    }
    return rootNode.build(); // tslint:disable-line:no-unsafe-any
  }

  public static encodeSmime = async (body: Uint8Array, headers: RichHeaders, type: 'enveloped-data' | 'signed-data'): Promise<string> => {
    const rootContentType = `application/pkcs7-mime; name="smime.p7m"; smime-type=${type}`;
    const rootNode = new MimeBuilder(rootContentType, { includeBccInHeader: true }); // tslint:disable-line:no-unsafe-any
    for (const key of Object.keys(headers)) {
      rootNode.addHeader(key, headers[key]); // tslint:disable-line:no-unsafe-any
    }
    rootNode.setContent(body); // tslint:disable-line:no-unsafe-any
    rootNode.addHeader('Content-Transfer-Encoding', 'base64'); // tslint:disable-line:no-unsafe-any
    rootNode.addHeader('Content-Disposition', 'attachment; filename="smime.p7m"'); // tslint:disable-line:no-unsafe-any
    let contentDescription = 'S/MIME Encrypted Message';
    if (type === 'signed-data') {
      contentDescription = 'S/MIME Signed Message';
    }
    rootNode.addHeader('Content-Description', contentDescription); // tslint:disable-line:no-unsafe-any
    return rootNode.build(); // tslint:disable-line:no-unsafe-any
  }

  public static subjectWithoutPrefixes = (subject: string): string => {
    return subject.replace(/^((Re|Fwd): ?)+/g, '').trim();
  }

  public static encodePgpMimeSigned = async (body: SendableMsgBody, headers: RichHeaders, attachments: Attachment[] = [], sign: (data: string) => Promise<string>): Promise<string> => {
    const sigPlaceholder = `SIG_PLACEHOLDER_${Str.sloppyRandom(10)}`;
    const rootNode = new MimeBuilder(`multipart/signed; protocol="application/pgp-signature";`, { includeBccInHeader: true }); // tslint:disable-line:no-unsafe-any
    for (const key of Object.keys(headers)) {
      rootNode.addHeader(key, headers[key]); // tslint:disable-line:no-unsafe-any
    }
    const bodyNodes = new MimeBuilder('multipart/alternative'); // tslint:disable-line:no-unsafe-any
    for (const type of Object.keys(body)) {
      bodyNodes.appendChild(Mime.newContentNode(MimeBuilder, type, body[type]!.toString())); // tslint:disable-line:no-unsafe-any
    }
    const signedContentNode = new MimeBuilder('multipart/mixed'); // tslint:disable-line:no-unsafe-any
    signedContentNode.appendChild(bodyNodes); // tslint:disable-line:no-unsafe-any
    for (const attachment of attachments) {
      signedContentNode.appendChild(Mime.createAttachmentNode(attachment)); // tslint:disable-line:no-unsafe-any
    }
    const sigAttachmentPlaceholder = new Attachment({ data: Buf.fromUtfStr(sigPlaceholder), type: 'application/pgp-signature', name: 'signature.asc' });
    const sigAttachmentPlaceholderNode = Mime.createAttachmentNode(sigAttachmentPlaceholder); // tslint:disable-line:no-unsafe-any
    // https://tools.ietf.org/html/rfc3156#section-5 - signed content first, signature after
    rootNode.appendChild(signedContentNode); // tslint:disable-line:no-unsafe-any
    rootNode.appendChild(sigAttachmentPlaceholderNode); // tslint:disable-line:no-unsafe-any
    const mimeStrWithPlaceholderSig = rootNode.build() as string; // tslint:disable-line:no-unsafe-any
    const { rawSignedContent } = await Mime.decode(Buf.fromUtfStr(mimeStrWithPlaceholderSig));
    if (!rawSignedContent) {
      console.log(`mimeStrWithPlaceholderSig(placeholder:${sigPlaceholder}):\n${mimeStrWithPlaceholderSig}`);
      throw new Error('Could not find raw signed content immediately after mime-encoding a signed message');
    }
    const realSignature = await sign(rawSignedContent); // tslint:disable-line:no-unsafe-any
    const pgpMimeSigned = mimeStrWithPlaceholderSig.replace(Buf.fromUtfStr(sigPlaceholder).toBase64Str(), Buf.fromUtfStr(realSignature).toBase64Str());
    if (pgpMimeSigned === mimeStrWithPlaceholderSig) {
      console.log(`pgpMimeSigned(placeholder:${sigPlaceholder}):\n${pgpMimeSigned}`);
      throw new Error('Replaced sigPlaceholder with realSignature but mime stayed the same');
    }
    return pgpMimeSigned;
  }

  private static headerGetAddress = (parsedMimeMsg: MimeContent, headersNames: Array<SendingType | 'from'>) => {
    const result: { to: string[], cc: string[], bcc: string[] } = { to: [], cc: [], bcc: [] };
    let from: string | undefined;
    const getHdrValAsArr = (hdr: MimeContentHeader) => typeof hdr === 'string' ? [hdr].map(h => Str.parseEmail(h).email).filter(e => !!e) as string[] : hdr.map(h => h.address);
    const getHdrValAsStr = (hdr: MimeContentHeader) => Str.parseEmail((Array.isArray(hdr) ? (hdr[0] || {}).address : String(hdr || '')) || '').email;
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
  }

  private static retrieveRawSignedContent = (nodes: MimeParserNode[]): string | undefined => {
    for (const node of nodes) {
      if (!node._childNodes || !node._childNodes.length) {
        continue; // signed nodes tend contain two children: content node, signature node. If no node, then this is not pgp/mime signed content
      }
      const isSigned = node._isMultipart === 'signed';
      const isMixedWithSig = node._isMultipart === 'mixed' && node._childNodes.length === 2 && Mime.getNodeType(node._childNodes[1]) === 'application/pgp-signature';
      if (isSigned || isMixedWithSig) {
        // PGP/MIME signed content uses <CR><LF> as in // use CR-LF https://tools.ietf.org/html/rfc3156#section-5
        // however emailjs parser will replace it to <LF>, so we fix it here
        let rawSignedContent = node._childNodes[0].raw.replace(/\r?\n/g, '\r\n');
        if (/--$/.test(rawSignedContent)) { // end of boundary without a mandatory newline
          rawSignedContent += '\r\n'; // emailjs wrongly leaves out the last newline, fix it here
        }
        return rawSignedContent;
      }
      return Mime.retrieveRawSignedContent(node._childNodes);
    }
    return undefined;
  }

  private static createAttachmentNode = (attachment: Attachment): any => { // todo: MimeBuilder types
    const type = `${attachment.type}; name="${attachment.name}"`;
    const id = attachment.cid || Attachment.attachmentId();
    const header: Dict<string> = {};
    if (attachment.contentDescription) {
      header['Content-Description'] = attachment.contentDescription;
    }
    header['Content-Disposition'] = attachment.inline ? 'inline' : 'attachment';
    header['X-Attachment-Id'] = id;
    header['Content-ID'] = `<${id}>`;
    header['Content-Transfer-Encoding'] = 'base64';
    return new MimeBuilder(type, { filename: attachment.name }).setHeader(header).setContent(attachment.getData()); // tslint:disable-line:no-unsafe-any
  }

  private static getNodeType = (node: MimeParserNode, type: 'value' | 'initial' = 'value') => {
    if (node.headers['content-type'] && node.headers['content-type'][0]) {
      return node.headers['content-type'][0][type];
    }
    return undefined;
  }

  private static getNodeContentId = (node: MimeParserNode) => {
    if (node.headers['content-id'] && node.headers['content-id'][0]) {
      return node.headers['content-id'][0].value;
    }
    return undefined;
  }

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
  }

  private static isNodeInline = (node: MimeParserNode): boolean => {
    const cd = node.headers['content-disposition'];
    return cd && cd[0] && cd[0].value === 'inline';
  }

  private static fromEqualSignNotationAsBuf = (str: string): Buf => {
    return Buf.fromRawBytesStr(str.replace(/(=[A-F0-9]{2})+/g, equalSignUtfPart => {
      const bytes = equalSignUtfPart.replace(/^=/, '').split('=').map(twoHexDigits => parseInt(twoHexDigits, 16));
      return new Buf(bytes).toRawBytesStr();
    }));
  }

  private static getNodeAsAttachment = (node: MimeParserNode): Attachment => {
    return new Attachment({
      name: Mime.getNodeFilename(node),
      type: Mime.getNodeType(node),
      data: node.contentTransferEncoding.value === 'quoted-printable' ? Mime.fromEqualSignNotationAsBuf(node.rawContent!) : node.content,
      cid: Mime.getNodeContentId(node),
    });
  }

  private static getNodeContentAsUtfStr = (node: MimeParserNode): string => {
    if (node.charset && Iso88592.labels.includes(node.charset)) {
      return Iso88592.decode(node.rawContent!); // tslint:disable-line:no-unsafe-any
    }
    let resultBuf: Buf;
    if (node.charset === 'utf-8' && node.contentTransferEncoding.value === 'base64') {
      resultBuf = Buf.fromUint8(node.content);
    } else if (node.charset === 'utf-8' && node.contentTransferEncoding.value === 'quoted-printable') {
      resultBuf = Mime.fromEqualSignNotationAsBuf(node.rawContent!);
    } else {
      resultBuf = Buf.fromRawBytesStr(node.rawContent!);
    }
    if (node.charset?.toUpperCase() === 'ISO-2022-JP' || (node.charset === 'utf-8' && Mime.getNodeType(node, 'initial')?.includes('ISO-2022-JP'))) {
      return iso2022jpToUtf(resultBuf);
    }
    return resultBuf.toUtfStr();
  }

  // tslint:disable-next-line:variable-name
  private static newContentNode = (MimeBuilder: any, type: string, content: string): MimeParserNode => {
    const node: MimeParserNode = new MimeBuilder(type).setContent(content); // tslint:disable-line:no-unsafe-any
    if (type === 'text/plain') {
      // gmail likes this
      node.addHeader('Content-Transfer-Encoding', 'quoted-printable'); // tslint:disable-line:no-unsafe-any
    }
    return node;
  }

}
