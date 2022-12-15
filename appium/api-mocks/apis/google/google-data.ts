/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { AddressObject, ParsedMail, StructuredHeader } from 'mailparser';
import { readFile, readdir } from 'fs';
import { lousyRandom } from '../../lib/mock-util';
import { GoogleConfig } from 'api-mocks/lib/configuration-types';
import { GoogleMockAccountEmail } from './google-messages';
import { MockUser, MockUserAlias } from 'api-mocks/mock-data';
import Parse from '../../util/parse';
import { TextDecoder } from 'util';

type GmailMsg$header = { name: string, value: string };
type GmailMsg$payload$body = { attachmentId?: string, size: number, data?: string };
type GmailMsg$payload$part = { partId?: string, body?: GmailMsg$payload$body, filename?: string, mimeType?: string, headers?: GmailMsg$header[], parts?: GmailMsg$payload$part[] };
type GmailMsg$payload = { partId?: string, filename?: string, parts?: GmailMsg$payload$part[], headers?: GmailMsg$header[], mimeType?: string, body?: GmailMsg$payload$body };
type GmailMsg$labelId = 'INBOX' | 'UNREAD' | 'CATEGORY_PERSONAL' | 'IMPORTANT' | 'SENT' | 'CATEGORY_UPDATES' | 'DRAFT' | 'TRASH';
type GmailThread = { historyId: string; id: string; snippet: string; };
type Label = { id: string, name: string, messageListVisibility: 'show' | 'hide', labelListVisibility: 'labelShow' | 'labelHide', type: 'system' };
type AcctDataFile = { messages: GmailMsg[]; drafts: GmailMsg[], attachments: { [id: string]: { data: string, size: number, filename?: string } }, labels: Label[], contacts: MockUser[], aliases: MockUserAlias[] };
type ExportedMsg = { acctEmail: string, full: GmailMsg, raw: GmailMsg, attachments: { [id: string]: { data: string, size: number } } };

export class GmailMsg {

  public id: string;
  public historyId: string;
  public sizeEstimate?: number;
  public threadId: string | null;
  public draftId?: string | null;
  public payload?: GmailMsg$payload;
  public internalDate?: number | string;
  public labelIds?: GmailMsg$labelId[];
  public snippet?: string;
  public raw?: string;

  constructor(msg: { id: string, labelIds?: GmailMsg$labelId[], raw: string, payload?: GmailMsg$payload, mimeMsg: ParsedMail, threadId?: string | null, draftId?: string | null }) {
    this.id = msg.id;
    this.historyId = msg.id;
    this.threadId = msg.threadId ?? msg.id;
    this.draftId = msg.draftId;
    this.labelIds = msg.labelIds;
    this.raw = msg.raw;
    this.sizeEstimate = Buffer.byteLength(msg.raw, "utf-8");

    const dateHeader = msg.mimeMsg.headers.get('date')! as Date;
    this.internalDate = dateHeader.getTime();

    if (msg.payload) {
      this.payload = msg.payload;
    } else {
      const contentTypeHeader = msg.mimeMsg.headers.get('content-type')! as StructuredHeader;
      const toHeader = msg.mimeMsg.headers.get('to')! as AddressObject;
      const ccHeader = msg.mimeMsg.headers.get('cc')! as AddressObject;
      const bccHeader = msg.mimeMsg.headers.get('bcc')! as AddressObject;
      const fromHeader = msg.mimeMsg.headers.get('from')! as AddressObject;
      const subjectHeader = msg.mimeMsg.headers.get('subject')! as string;

      const messageIdHeader = msg.mimeMsg.headers.get('message-id')! as string;
      const mimeVersionHeader = msg.mimeMsg.headers.get('mime-version')! as string;
      const replyToHeader = msg.mimeMsg.headers.get('reply-to')! as AddressObject;
      let body;

      const attachmentId = `attachment_id_${lousyRandom()}`;
      if (msg.mimeMsg.text) {
        const textBase64 = Buffer.from(msg.mimeMsg.text, 'utf-8').toString('base64');
        body = { attachmentId: attachmentId, size: textBase64.length, data: textBase64 };
      } else if (typeof msg.mimeMsg.html === 'string') {
        const htmlBase64 = Buffer.from(msg.mimeMsg.html, 'utf-8').toString('base64');
        body = { attachmentId: attachmentId, size: htmlBase64.length, data: htmlBase64 };
      }

      const headers = [
        { name: "Content-Type", value: `${contentTypeHeader.value}; boundary="${contentTypeHeader.params.boundary}"` },
        { name: "Message-Id", value: messageIdHeader },
        { name: "Mime-Version", value: mimeVersionHeader }
      ];

      if (toHeader) {
        headers.push({ name: 'To', value: toHeader.text });
      }
      if (ccHeader) {
        headers.push({ name: 'Cc', value: ccHeader.text });
      }
      if (bccHeader) {
        headers.push({ name: 'Bcc', value: bccHeader.text });
      }
      if (fromHeader) {
        headers.push({ name: 'From', value: fromHeader.text });
      }
      if (subjectHeader) {
        headers.push({ name: 'Subject', value: subjectHeader });
      }
      if (dateHeader) {
        headers.push({ name: 'Date', value: dateHeader.toString() });
      }
      if (replyToHeader) {
        headers.push({ name: 'Reply-To', value: replyToHeader.text });
      }

      this.payload = {
        mimeType: contentTypeHeader.value,
        headers: headers,
        body
      };
    }
  }

  public updateLabels = (addLabels: string[], removeLabels: string[]) => {
    const addLabelsIds = addLabels as GmailMsg$labelId[];
    const removeLabelsIds = removeLabels as GmailMsg$labelId[];

    if (addLabelsIds) {
      this.labelIds = this.labelIds?.concat(addLabelsIds);
    }

    if (removeLabelsIds) {
      this.labelIds = this.labelIds?.filter((l) => !removeLabelsIds.includes(l));
    }
  }
}

export class GmailParser {

  public static findHeader = (apiGmailMsgObj: GmailMsg | GmailMsg$payload, headerName: string) => {
    const node: GmailMsg$payload = apiGmailMsgObj.hasOwnProperty('payload') ? (apiGmailMsgObj as GmailMsg).payload! : apiGmailMsgObj as GmailMsg$payload;
    if (typeof node.headers !== 'undefined') {
      for (const header of node.headers) {
        if (header.name.toLowerCase() === headerName.toLowerCase()) {
          return header.value;
        }
      }
    }
    return undefined;
  };

}

const DATA: { [acct: string]: AcctDataFile } = {};

/**
 * This class is badly designed - it acts like a class (whose object should contain its own data),
 *   but the data is shared globally across objects. Would be more appropriate to make this a static class.
 *   Either that, or have each instance hold data independently (unless it turns out there are memory issues)
 */
export class GoogleData {

  /**
   * This is the proper way to add messages to mock api for testing:
   *   1) log into flowcrypt.compatibility@gmail.com
   *   2) go to Settings -> Inbox and find your message
   *   3) click "download api export"
   *   4) save the json file to exported-messages folder
   */
  private static exportedMsgsPath = './api-mocks/apis/google/exported-messages/';

  public static withInitializedData = async (acct: GoogleMockAccountEmail, config?: GoogleConfig): Promise<GoogleData> => {
    if (typeof DATA[acct] === 'undefined') {
      const contacts = config?.accounts[acct]?.contacts ?? [];
      const aliases: MockUserAlias[] = [{
        sendAsEmail: acct,
        displayName: '',
        replyToAddress: acct,
        signature: '',
        isDefault: true,
        isPrimary: true,
        treatAsAlias: false,
        verificationStatus: 'accepted'
      }];
      const additionalAliases = config?.accounts[acct]?.aliases ?? [];
      const acctData: AcctDataFile = {
        drafts: [], messages: [], attachments: {}, contacts: contacts,
        aliases: [...aliases, ...additionalAliases],
        labels:
          [
            { id: 'INBOX', name: 'Inbox', messageListVisibility: 'show', labelListVisibility: 'labelShow', type: 'system' },
            { id: 'SENT', name: 'Sent', messageListVisibility: 'show', labelListVisibility: 'labelShow', type: 'system' },
            { id: 'DRAFT', name: 'Drafts', messageListVisibility: 'show', labelListVisibility: 'labelShow', type: 'system' },
            { id: 'TRASH', name: 'Trash', messageListVisibility: 'show', labelListVisibility: 'labelShow', type: 'system' },
          ]
      };

      DATA[acct] = acctData;
    }

    await this.parseAcctMessages(acct, config);

    return new GoogleData(acct);
  };

  public static fmtMsg = (m: GmailMsg, format: 'raw' | 'full' | 'metadata' | string) => {
    format = format || 'full';
    if (!['raw', 'full', 'metadata'].includes(format)) {
      throw new Error(`Unknown format: ${format}`);
    }
    const msgCopy = JSON.parse(JSON.stringify(m)) as GmailMsg;
    if (format === 'raw') {
      if (!msgCopy.raw) {
        throw new Error(`MOCK: format=raw missing data for message id ${m.id}. Solution: add them to ./test/source/mock/data/google/exported-messages`);
      }
    } else {
      msgCopy.raw = undefined;
    }
    if (msgCopy.payload && (['metadata', 'raw'].includes(format))) {
      msgCopy.payload.body = undefined;
      msgCopy.payload.parts = undefined;
    }

    return msgCopy;
  };

  private static msgSubject = (m: GmailMsg): string => {
    const subjectHeader = m.payload && m.payload.headers && m.payload.headers.find(h => h.name === 'Subject');
    return (subjectHeader && subjectHeader.value) || '';
  };

  private static msgId = (m: GmailMsg): string => {
    const msgIdHeader = m.payload && m.payload.headers && m.payload.headers.find(h => h.name.toLowerCase() === 'message-id');
    return (msgIdHeader && msgIdHeader.value) || '';
  };

  private static parseAcctMessages = async (acct: GoogleMockAccountEmail, config?: GoogleConfig) => {
    if (config?.accounts[acct]?.messages) {
      const dir = GoogleData.exportedMsgsPath;
      const filenames: string[] = await new Promise((res, rej) => readdir(dir, (e, f) => e ? rej(e) : res(f)));
      const validFiles = filenames.filter(item => !/(^|\/)\.[^/.]/g.test(item)); // ignore hidden files
      const filePromises = validFiles.map(f => new Promise((res, rej) => readFile(dir + f, (e, d) => e ? rej(e) : res(d))));
      const files = await Promise.all(filePromises) as Uint8Array[];
      const msgSubjects = config?.accounts[acct]?.messages?.map(m => m.toString());
      const existingMessages = DATA[acct].messages.map(m => m.id);
      for (const file of files) {
        const utfStr = new TextDecoder().decode(file);
        const json = JSON.parse(utfStr) as ExportedMsg;

        const subject = GoogleData.msgSubject(json.full).replace('Re: ', '');
        const isValidMsg = msgSubjects ? msgSubjects.includes(subject) : json.acctEmail === acct;

        if (isValidMsg) {
          const raw = json.raw.raw;

          if (!raw || existingMessages.includes(json.raw.id)) { continue; }

          const mimeMsg = await Parse.convertBase64ToMimeMsg(raw);
          const msg = new GmailMsg({ id: json.raw.id, labelIds: json.full.labelIds, raw: raw, payload: json.full.payload, mimeMsg: mimeMsg, threadId: json.full.threadId });
          if (json.full.labelIds && json.full.labelIds.includes('DRAFT')) {
            DATA[acct].drafts.push(msg);
          } else {
            DATA[acct].messages.push(msg);
          }

          if (json.attachments) {
            DATA[acct].attachments = { ...DATA[acct].attachments, ...json.attachments };
          }
        }
      }
    }
  }

  constructor(private acct: string) {
    if (!DATA[acct]) {
      throw new Error('Missing DATA: use withInitializedData instead of direct constructor');
    }
  }

  public getUserInfo = () => {
    return {
      id: '1',
      email: this.acct,
      name: 'First Last',
      given_name: 'First',
      family_name: 'Last',
      picture: '',
    }
  }

  public getAliases = () => {
    return DATA[this.acct].aliases;
  }

  public getMessage = (id: string): GmailMsg | undefined => {
    return this.getMessagesAndDrafts().find(m => m.id === id);
  };

  public getMessageBySubject = (subject: string): GmailMsg | undefined => {
    return DATA[this.acct].messages.find(m => {
      if (m.payload?.headers) {
        const subjectHeader = m.payload.headers.find(x => x.name === 'Subject');
        if (subjectHeader) {
          return subjectHeader.value.includes(subject);
        }
      }
      return false;
    });
  };

  public getMessagesAndDraftsByThread = (threadId: string) => {
    return this.getMessagesAndDrafts().filter(m => m.threadId === threadId);
  };

  public getMessagesByThread = (threadId: string) => {
    return DATA[this.acct].messages.filter(m => m.threadId === threadId);
  };

  public updateMessageLabels = (addLabels: string[], removeLabels: string[], messageId?: string, threadId?: string) => {
    for (const index in DATA[this.acct].messages) {
      if ((messageId && DATA[this.acct].messages[index].id == messageId) || (threadId && DATA[this.acct].messages[index].threadId == threadId)) {
        DATA[this.acct].messages[index].updateLabels(addLabels, removeLabels);
      }
    }
  }

  public updateBatchMessageLabels = (addLabels: string[], removeLabels: string[], messageIds: string[]) => {
    for (const messageId of messageIds) {
      const index = DATA[this.acct].messages.findIndex((message) => message.id == messageId);
      if (index > -1) {
        DATA[this.acct].messages[index].updateLabels(addLabels, removeLabels);
      }
    }
  }

  public getMessages = (labelIds: string[] = [], query?: string) => {
    const subject = (query?.match(/subject: '([^"]+)'/) || [])[1]?.trim().toLowerCase();
    const rfc822Msgid = (query?.match(/rfc822msgid:([^"]+)/) || [])[1]?.trim();
    return DATA[this.acct].messages.filter(m => {
      if (subject && !GoogleData.msgSubject(m).toLowerCase().includes(subject)) {
        return false;
      }
      if (rfc822Msgid && GoogleData.msgId(m) !== rfc822Msgid) {
        return false;
      }
      if (labelIds && !m.labelIds?.some(l => labelIds.includes(l))) {
        return false;
      }

      return true;
    });
  };

  public addMessage = (raw: string, mimeMsg: ParsedMail) => {
    const id = `msg_id_${lousyRandom()}`;

    // fix raw for iOS parser
    const decodedRaw = Buffer.from(raw, 'base64').toString().replace(/sinikael-\?=/g, 'sinikael-=');
    const rawBase64 = Buffer.from(decodedRaw).toString('base64');

    const msg = new GmailMsg({ labelIds: ['SENT'], id, raw: rawBase64, mimeMsg });
    DATA[this.acct].messages = DATA[this.acct].messages.filter(m => GoogleData.msgId(m) === mimeMsg.messageId);
    DATA[this.acct].messages.unshift(msg);
  };

  public deleteThread = (threadId: string) => {
    DATA[this.acct].messages = DATA[this.acct].messages.filter(m => m.threadId != threadId);
  }

  public deleteMessages = (ids: string[]) => {
    DATA[this.acct].messages = DATA[this.acct].messages.filter(m => !ids.includes(m.id));
  }

  public deleteDraft = (id: string) => {
    DATA[this.acct].messages = DATA[this.acct].messages.filter(m => id !== m.draftId);
  }

  public addDraft = (raw: string, mimeMsg: ParsedMail, id?: string, threadId?: string) => {
    const draftId = id ?? `draft_id_${lousyRandom()}`;
    const msgId = `msg_id_${lousyRandom()}`;
    const draft = new GmailMsg({ labelIds: ['DRAFT'], id: msgId, raw, mimeMsg, threadId: threadId, draftId: draftId });
    const index = DATA[this.acct].messages.findIndex(d => d.draftId === draftId);

    if (index === -1) {
      DATA[this.acct].messages.push(draft);
    } else {
      DATA[this.acct].messages[index] = draft;
    }

    return draft;
  };

  public getDraft = (id: string): GmailMsg | undefined => {
    return DATA[this.acct].messages.find(d => d.draftId === id);
  };

  public getAttachment = (attachmentId: string) => {
    return DATA[this.acct].attachments[attachmentId];
  };

  public getLabels = () => {
    return DATA[this.acct].labels;
  };

  public getThreads = (labelIds: string[] = [], query?: string) => {
    const subject = (query?.match(/subject: '([^"]+)'/) || [])[1]?.trim().toLowerCase();
    const threads: GmailThread[] = [];

    const filteredThreads = this.getMessagesAndDrafts().
      filter(m => {
        if (labelIds.length) {
          const messageLabels = m.labelIds || [];
          if (messageLabels.includes('TRASH')) {
            return labelIds.includes('TRASH');
          } else {
            return messageLabels.some(l => labelIds.includes(l));
          }
        } else {
          return true;
        }
      }).
      filter(m => subject ? GoogleData.msgSubject(m).toLowerCase().includes(subject) : true).
      map(m => ({ historyId: m.historyId, id: m.threadId!, snippet: `MOCK SNIPPET: ${GoogleData.msgSubject(m)}` }))

    for (const thread of filteredThreads) {
      if (thread.id && !threads.map(t => t.id).includes(thread.id)) {
        threads.push(thread);
      }
    }

    return threads;
  };

  public searchContacts = (query: string) => {
    return DATA[this.acct].contacts.filter(contact => {
      const contactData = [contact.name, contact.email].join(' ').toLowerCase();
      return contactData.includes(query.toLowerCase());
    });
  }

  // returns ordinary messages and drafts
  private getMessagesAndDrafts = () => {
    return DATA[this.acct].messages.concat(DATA[this.acct].drafts);
  };

}
