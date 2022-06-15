/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import * as forge from 'node-forge';
import { AddressObject, ParsedMail, StructuredHeader } from 'mailparser';
import { ITestMsgStrategy, UnsuportableStrategyError } from './strategy-base';
import { Buf } from '../../../core/buf';
import { Config } from '../config';
import { GoogleData } from '../google-data';
import { HttpErr } from '../../../lib/api';
import { MsgUtil } from '../../../core/crypto/pgp/msg-util';
import Parse from '../../../util/parse';
import { parsedMailAddressObjectAsArray } from '../google-endpoints';
import { Str } from '../../../core/common';
import { GMAIL_RECOVERY_EMAIL_SUBJECTS } from '../../../core/const';
import { ENVELOPED_DATA_OID, SIGNED_DATA_OID, SmimeKey } from '../../../core/crypto/smime/smime-key';
import { testConstants } from '../constants';

// TODO: Make a better structure of ITestMsgStrategy. Because this class doesn't test anything, it only saves message in the Mock
class SaveMessageInStorageStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail, base64Msg: string, id: string) => {
    (await GoogleData.withInitializedData(mimeMsg.from!.value[0].address!)).storeSentMessage(mimeMsg, base64Msg, id);
  };
}

class PwdEncryptedMessageWithFlowCryptComApiTestStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail) => {
    const senderEmail = Str.parseEmail(mimeMsg.from!.text).email;
    if (!mimeMsg.text?.includes(`${senderEmail} has sent you a password-encrypted email`)) {
      throw new HttpErr(`Error checking sent text in:\n\n${mimeMsg.text}`);
    }
    if (!mimeMsg.text?.match(/https:\/\/flowcrypt.com\/[a-z0-9A-Z]{10}/)) {
      throw new HttpErr(`Error: cannot find pwd encrypted flowcrypt.com/api link in:\n\n${mimeMsg.text}`);
    }
    if (!mimeMsg.text?.includes('Follow this link to open it')) {
      throw new HttpErr(`Error: cannot find pwd encrypted open link prompt in ${mimeMsg.text}`);
    }
  };
}

class PwdEncryptedMessageWithFesIdTokenTestStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail, base64Msg: string, id: string) => {
    const expectedSenderEmail = 'user@standardsubdomainfes.test:8001';
    expect(mimeMsg.from!.text).toEqual(`First Last <${expectedSenderEmail}>`);
    expect((mimeMsg.to as AddressObject).text).toEqual('Mr To <to@example.com>');
    expect((mimeMsg.bcc as AddressObject).text).toEqual('Mr Bcc <bcc@example.com>');
    if (!mimeMsg.text?.includes(`${expectedSenderEmail} has sent you a password-encrypted email`)) {
      throw new HttpErr(`Error checking sent text in:\n\n${mimeMsg.text}`);
    }
    if (!mimeMsg.text?.includes('http://fes.standardsubdomainfes.test:8001/message/FES-MOCK-MESSAGE-ID')) { // lgtm [js/incomplete-url-substring-sanitization]
      throw new HttpErr(`Error: cannot find pwd encrypted FES link in:\n\n${mimeMsg.text}`);
    }
    if (!mimeMsg.text?.includes('Follow this link to open it')) {
      throw new HttpErr(`Error: cannot find pwd encrypted open link prompt in ${mimeMsg.text}`);
    }
    await new SaveMessageInStorageStrategy().test(mimeMsg, base64Msg, id);
  };
}

class MessageWithFooterTestStrategy implements ITestMsgStrategy {
  private readonly footer = 'flowcrypt.compatibility test footer with an img';

  public test = async (mimeMsg: ParsedMail) => {
    const keyInfo = await Config.getKeyInfo(["flowcrypt.compatibility.1pp1", "flowcrypt.compatibility.2pp1"]);
    const decrypted = await MsgUtil.decryptMessage({ kisWithPp: keyInfo!, encryptedData: Buf.fromUtfStr(mimeMsg.text || ''), verificationPubs: [] });
    if (!decrypted.success) {
      throw new HttpErr(`Error: can't decrypt message`);
    }
    const textContent = decrypted.content.toUtfStr();
    if (!textContent.includes(this.footer)) {
      throw new HttpErr(`Error: Msg Text doesn't contain footer. Current: '${mimeMsg.text}', expected footer: '${this.footer}'`);
    }
  };
}

class SignedMessageTestStrategy implements ITestMsgStrategy {
  private readonly expectedText = 'New Signed Message (Mock Test)';
  private readonly signedBy = 'B6BE3C4293DDCF66'; // could potentially grab this from test-secrets.json file

  public test = async (mimeMsg: ParsedMail) => {
    const keyInfo = await Config.getKeyInfo(["flowcrypt.compatibility.1pp1", "flowcrypt.compatibility.2pp1"]);
    const decrypted = await MsgUtil.decryptMessage({ kisWithPp: keyInfo!, encryptedData: Buf.fromUtfStr(mimeMsg.text!), verificationPubs: [] });
    if (!decrypted.success) {
      throw new HttpErr(`Error: Could not successfully verify signed message`);
    }
    if (!decrypted.signature) {
      throw new HttpErr(`Error: The message isn't signed.`);
    }
    if (!(decrypted.signature.signer?.longid == this.signedBy)) {
      // TODO
      throw new HttpErr(`Error: expected message signed by ${this.signedBy} but was actually signed by ${decrypted.signature.signer?.longid.length} other signers`);
    }
    const content = decrypted.content.toUtfStr();
    if (!content.includes(this.expectedText)) {
      throw new HttpErr(`Error: Contents don't match. Expected: '${this.expectedText}' but got: '${content}'.`);
    }
  };
}

class PlainTextMessageTestStrategy implements ITestMsgStrategy {
  private readonly expectedText = 'New Plain Message';

  public test = async (mimeMsg: ParsedMail) => {
    if (!mimeMsg.text?.includes(this.expectedText)) {
      throw new HttpErr(`Error: Msg Text is not matching expected. Current: '${mimeMsg.text}', expected: '${this.expectedText}'`);
    }
  };
}

class IncludeQuotedPartTestStrategy implements ITestMsgStrategy {
  private readonly quotedContent: string = [
    'On 2019-06-14 at 23:24, flowcrypt.compatibility@gmail.com wrote:',
    '> This is some message',
    '>',
    '> and below is the quote',
    '>',
    '> > this is the quote',
    '> > still the quote',
    '> > third line',
    '> >> double quote',
    '> >> again double quote'
  ].join('\n');

  public test = async (mimeMsg: ParsedMail) => {
    const keyInfo = await Config.getKeyInfo(["flowcrypt.compatibility.1pp1", "flowcrypt.compatibility.2pp1"]);
    const decrypted = await MsgUtil.decryptMessage({ kisWithPp: keyInfo!, encryptedData: Buf.fromUtfStr(mimeMsg.text!), verificationPubs: [] });
    if (!decrypted.success) {
      throw new HttpErr(`Error: can't decrypt message`);
    }
    const textContent = decrypted.content.toUtfStr();
    if (!textContent.endsWith(this.quotedContent)) {
      throw new HttpErr(`Error: Quoted content isn't included to the Msg. Msg text: '${textContent}'\n Quoted part: '${this.quotedContent}'`, 400);
    }
  };
}

class NewMessageCCAndBCCTestStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail) => {
    const hasAtLeastOneRecipient = (ao: AddressObject[]) => ao && ao.length && ao[0].value && ao[0].value.length && ao[0].value[0].address;
    if (!hasAtLeastOneRecipient(parsedMailAddressObjectAsArray(mimeMsg.to))) {
      throw new HttpErr(`Error: There is no 'To' header.`, 400);
    }
    if (!hasAtLeastOneRecipient(parsedMailAddressObjectAsArray(mimeMsg.cc))) {
      throw new HttpErr(`Error: There is no 'Cc' header.`, 400);
    }
    if (!hasAtLeastOneRecipient(parsedMailAddressObjectAsArray(mimeMsg.bcc))) {
      throw new HttpErr(`Error: There is no 'Bcc' header.`, 400);
    }
  };
}

class SmimeEncryptedMessageStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail) => {
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).value).toEqual('application/pkcs7-mime');
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).params.name).toEqual('smime.p7m');
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).params['smime-type']).toEqual('enveloped-data');
    expect(mimeMsg.headers.get('content-transfer-encoding')).toEqual('base64');
    expect((mimeMsg.headers.get('content-disposition') as StructuredHeader).value).toEqual('attachment');
    expect((mimeMsg.headers.get('content-disposition') as StructuredHeader).params.filename).toEqual('smime.p7m');
    expect(mimeMsg.headers.get('content-description')).toEqual('S/MIME Encrypted Message');
    expect(mimeMsg.attachments!.length).toEqual(1);
    expect(mimeMsg.attachments![0].contentType).toEqual('application/pkcs7-mime');
    expect(mimeMsg.attachments![0].filename).toEqual('smime.p7m');
    const withAttachments = mimeMsg.subject?.includes(' with attachment');
    expect(mimeMsg.attachments![0].size).toBeGreaterThan(withAttachments ? 20000 : 300);
    const msg = new Buf(mimeMsg.attachments![0].content).toRawBytesStr();
    const p7 = forge.pkcs7.messageFromAsn1(forge.asn1.fromDer(msg));
    expect(p7.type).toEqual(ENVELOPED_DATA_OID);
    if (p7.type === ENVELOPED_DATA_OID) {
      const key = SmimeKey.parse(testConstants.testKeyMultipleSmimeCEA2D53BB9D24871);
      const decrypted = SmimeKey.decryptMessage(p7, key);
      const decryptedMessage = Buf.with(decrypted).toRawBytesStr();
      if (mimeMsg.subject?.includes(' signed ')) {
        expect(decryptedMessage).toContain('smime-type=signed-data');
        // todo: parse PKCS#7, check that is of SIGNED_DATA_OID content type, extract content?
        // todo: #4046
      } else {
        expect(decryptedMessage).toContain('This text should be encrypted into PKCS#7 data');
        if (withAttachments) {
          const nestedMimeMsg = await Parse.parseMixed(decryptedMessage);
          expect(nestedMimeMsg.attachments!.length).toEqual(3);
          expect(nestedMimeMsg.attachments![0].content.toString()).toEqual(`small text file\nnot much here\nthis worked\n`);
        }
      }
    }
  };
}

class SmimeSignedMessageStrategy implements ITestMsgStrategy {
  public test = async (mimeMsg: ParsedMail) => {
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).value).toEqual('application/pkcs7-mime');
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).params.name).toEqual('smime.p7m');
    expect((mimeMsg.headers.get('content-type') as StructuredHeader).params['smime-type']).toEqual('signed-data');
    expect(mimeMsg.headers.get('content-transfer-encoding')).toEqual('base64');
    expect((mimeMsg.headers.get('content-disposition') as StructuredHeader).value).toEqual('attachment');
    expect((mimeMsg.headers.get('content-disposition') as StructuredHeader).params.filename).toEqual('smime.p7m');
    expect(mimeMsg.headers.get('content-description')).toEqual('S/MIME Signed Message');
    expect(mimeMsg.attachments!.length).toEqual(1);
    expect(mimeMsg.attachments![0].contentType).toEqual('application/pkcs7-mime');
    expect(mimeMsg.attachments![0].filename).toEqual('smime.p7m');
    expect(mimeMsg.attachments![0].size).toBeGreaterThan(300);
    const msg = new Buf(mimeMsg.attachments![0].content).toRawBytesStr();
    const p7 = forge.pkcs7.messageFromAsn1(forge.asn1.fromDer(msg));
    expect(p7.type).toEqual(SIGNED_DATA_OID);
  };
}
export class TestBySubjectStrategyContext {
  private strategy: ITestMsgStrategy;

  constructor(subject: string) {
    if (subject.includes('testing quotes')) {
      this.strategy = new IncludeQuotedPartTestStrategy();
    } else if (subject.includes('Testing CC And BCC')) {
      this.strategy = new NewMessageCCAndBCCTestStrategy();
    } else if (subject.includes('New Plain Message')) {
      this.strategy = new PlainTextMessageTestStrategy();
    } else if (subject.includes('New Signed Message (Mock Test)')) {
      this.strategy = new SignedMessageTestStrategy();
    } else if (subject.includes('Test Footer (Mock Test)')) {
      this.strategy = new MessageWithFooterTestStrategy();
    } else if (subject.includes('PWD encrypted message with flowcrypt.com/api')) {
      this.strategy = new PwdEncryptedMessageWithFlowCryptComApiTestStrategy();
    } else if (subject.includes('PWD encrypted message with FES - ID TOKEN')) {
      this.strategy = new PwdEncryptedMessageWithFesIdTokenTestStrategy();
    } else if (subject.includes('Message With Image')) {
      this.strategy = new SaveMessageInStorageStrategy();
    } else if (subject.includes('Message With Test Text')) {
      this.strategy = new SaveMessageInStorageStrategy();
    } else if (subject.includes('send with single S/MIME cert')) {
      this.strategy = new SmimeEncryptedMessageStrategy();
    } else if (subject.includes('send with several S/MIME certs')) {
      this.strategy = new SmimeEncryptedMessageStrategy();
    } else if (subject.includes('S/MIME message')) {
      this.strategy = new SmimeEncryptedMessageStrategy();
    } else if (subject.includes('send signed S/MIME without attachment')) {
      this.strategy = new SmimeSignedMessageStrategy();
    } else if (GMAIL_RECOVERY_EMAIL_SUBJECTS.includes(subject)) {
      this.strategy = new SaveMessageInStorageStrategy();
    } else {
      throw new UnsuportableStrategyError(`There isn't any strategy for this subject: ${subject}`);
    }
  }

  public test = async (mimeMsg: ParsedMail, base64Msg: string, id: string) => {
    await this.strategy.test(mimeMsg, base64Msg, id);
  };
}
