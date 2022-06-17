/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { AddressObject, ParsedMail } from 'mailparser';
import { ITestMsgStrategy, UnsuportableStrategyError } from './strategy-base';
import { HttpErr } from '../../../lib/api';
import { parsedMailAddressObjectAsArray } from '../google-endpoints';
import { Str } from '../../../core/common';

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
    } else {
      throw new UnsuportableStrategyError(`There isn't any strategy for this subject: ${subject}`);
    }
  }

  public test = async (mimeMsg: ParsedMail, base64Msg: string, id: string) => {
    await this.strategy.test(mimeMsg, base64Msg, id);
  };
}
