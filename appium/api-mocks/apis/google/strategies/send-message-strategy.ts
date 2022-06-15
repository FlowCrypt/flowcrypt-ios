/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { AddressObject, ParsedMail } from 'mailparser';
import { ITestMsgStrategy, UnsuportableStrategyError } from './strategy-base';
import { GoogleData } from '../google-data';
import { HttpErr } from '../../../lib/api';
import { parsedMailAddressObjectAsArray } from '../google-endpoints';
import { Str } from '../../../core/common';
import { GMAIL_RECOVERY_EMAIL_SUBJECTS } from '../../../core/const';

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

class PlainTextMessageTestStrategy implements ITestMsgStrategy {
  private readonly expectedText = 'New Plain Message';

  public test = async (mimeMsg: ParsedMail) => {
    if (!mimeMsg.text?.includes(this.expectedText)) {
      throw new HttpErr(`Error: Msg Text is not matching expected. Current: '${mimeMsg.text}', expected: '${this.expectedText}'`);
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

export class TestBySubjectStrategyContext {
  private strategy: ITestMsgStrategy;

  constructor(subject: string) {
    if (subject.includes('Testing CC And BCC')) {
      this.strategy = new NewMessageCCAndBCCTestStrategy();
    } else if (subject.includes('New Plain Message')) {
      this.strategy = new PlainTextMessageTestStrategy();
    } else if (subject.includes('PWD encrypted message with flowcrypt.com/api')) {
      this.strategy = new PwdEncryptedMessageWithFlowCryptComApiTestStrategy();
    } else if (subject.includes('PWD encrypted message with FES - ID TOKEN')) {
      this.strategy = new PwdEncryptedMessageWithFesIdTokenTestStrategy();
    } else if (subject.includes('Message With Image')) {
      this.strategy = new SaveMessageInStorageStrategy();
    } else if (subject.includes('Message With Test Text')) {
      this.strategy = new SaveMessageInStorageStrategy();
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
