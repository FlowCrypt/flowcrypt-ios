/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { AddressObject, ParsedMail, StructuredHeader } from 'mailparser';
import { readFile, readdir } from 'fs';
import { lousyRandom } from '../../lib/mock-util';
import { GoogleConfig } from 'api-mocks/lib/configuration-types';
import { GoogleMockAccountEmail } from './google-messages';
import { MockUser, MockUserAlias } from 'api-mocks/mock-data';

type GmailMsg$header = { name: string, value: string };
type GmailMsg$payload$body = { attachmentId?: string, size: number, data?: string };
type GmailMsg$payload$part = { partId?: string, body?: GmailMsg$payload$body, filename?: string, mimeType?: string, headers?: GmailMsg$header[], parts?: GmailMsg$payload$part[] };
type GmailMsg$payload = { partId?: string, filename?: string, parts?: GmailMsg$payload$part[], headers?: GmailMsg$header[], mimeType?: string, body?: GmailMsg$payload$body };
type GmailMsg$labelId = 'INBOX' | 'UNREAD' | 'CATEGORY_PERSONAL' | 'IMPORTANT' | 'SENT' | 'CATEGORY_UPDATES' | 'DRAFT';
type GmailThread = { historyId: string; id: string; snippet: string; };
type Label = { id: string, name: string, messageListVisibility: 'show' | 'hide', labelListVisibility: 'labelShow' | 'labelHide', type: 'system' };
type AcctDataFile = { messages: GmailMsg[]; drafts: GmailMsg[], attachments: { [id: string]: { data: string, size: number, filename?: string } }, labels: Label[], contacts: MockUser[], aliases: MockUserAlias[] };
type ExportedMsg = { acctEmail: string, full: GmailMsg, raw: GmailMsg, attachments: { [id: string]: { data: string, size: number } } };

export class GmailMsg {

  public id: string;
  public historyId: string;
  public sizeEstimate?: number;
  public threadId: string | null;
  public payload?: GmailMsg$payload;
  public internalDate?: number | string;
  public labelIds?: GmailMsg$labelId[];
  public snippet?: string;
  public raw?: string;

  constructor(msg: { id: string, labelId: GmailMsg$labelId, raw: string, mimeMsg: ParsedMail }) {
    this.id = msg.id;
    this.historyId = msg.id;
    this.threadId = msg.id;
    this.labelIds = [msg.labelId];
    this.raw = msg.raw;
    this.sizeEstimate = Buffer.byteLength(msg.raw, "utf-8");

    const contentTypeHeader = msg.mimeMsg.headers.get('content-type')! as StructuredHeader;
    const toHeader = msg.mimeMsg.headers.get('to')! as AddressObject;
    const fromHeader = msg.mimeMsg.headers.get('from')! as AddressObject;
    const subjectHeader = msg.mimeMsg.headers.get('subject')! as string;
    const dateHeader = msg.mimeMsg.headers.get('date')! as Date;
    const messageIdHeader = msg.mimeMsg.headers.get('message-id')! as string;
    const mimeVersionHeader = msg.mimeMsg.headers.get('mime-version')! as string;
    let body;

    if (msg.mimeMsg.text) {
      const textBase64 = Buffer.from(msg.mimeMsg.text, 'utf-8').toString('base64');
      body = { attachmentId: '', size: textBase64.length, data: textBase64 };
    } else if (typeof msg.mimeMsg.html === 'string') {
      const htmlBase64 = Buffer.from(msg.mimeMsg.html, 'utf-8').toString('base64');
      body = { attachmentId: '', size: htmlBase64.length, data: htmlBase64 };
    }
    this.internalDate = dateHeader.getTime();
    this.payload = {
      mimeType: contentTypeHeader.value,
      headers: [
        { name: "Content-Type", value: `${contentTypeHeader.value}; boundary="${contentTypeHeader.params.boundary}"` },
        { name: "Message-Id", value: messageIdHeader },
        { name: "Mime-Version", value: mimeVersionHeader }
      ],
      body
    };
    if (toHeader) {
      this.payload.headers!.push({ name: 'To', value: toHeader.value.map(a => a.address).join(',') });
    }
    if (fromHeader) {
      this.payload.headers!.push({ name: 'From', value: fromHeader.value[0].address! });
    }
    if (subjectHeader) {
      this.payload.headers!.push({ name: 'Subject', value: subjectHeader });
    }
    if (dateHeader) {
      this.payload.headers!.push({ name: 'Date', value: dateHeader.toString() });
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

  private exludePplSearchQuery = /(?:-from|-to):"?([a-zA-Z0-9@.\-_]+)"?/g;
  private includePplSearchQuery = /(?:from|to):"?([a-zA-Z0-9@.\-_]+)"?/g;

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
      const dir = GoogleData.exportedMsgsPath;
      const filenames: string[] = await new Promise((res, rej) => readdir(dir, (e, f) => e ? rej(e) : res(f)));
      const validFiles = filenames.filter(item => !/(^|\/)\.[^/.]/g.test(item)); // ignore hidden files
      const filePromises = validFiles.map(f => new Promise((res, rej) => readFile(dir + f, (e, d) => e ? rej(e) : res(d))));
      const files = await Promise.all(filePromises) as Uint8Array[];
      const msgSubjects = config?.accounts[acct]?.messages?.map(m => m.toString());

      for (const file of files) {
        const utfStr = new TextDecoder().decode(file);
        const json = JSON.parse(utfStr) as ExportedMsg;
        const subject = GoogleData.msgSubject(json.full).replace('Re: ', '');
        const isValidMsg = msgSubjects ? msgSubjects.includes(subject) : json.acctEmail === acct;

        if (isValidMsg) {
          Object.assign(acctData.attachments, json.attachments);
          json.full.raw = json.raw.raw;
          if (json.full.labelIds && json.full.labelIds.includes('DRAFT')) {
            acctData.drafts.push(json.full);
          } else {
            acctData.messages.push(json.full);
          }
        }
      }
      DATA[acct] = acctData;
    }
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
    if (format === 'metadata' || format === 'raw') {
      if (msgCopy.payload) {
        msgCopy.payload.body = undefined;
        msgCopy.payload.parts = undefined;
      }
    }
    return msgCopy;
  };

  private static msgSubject = (m: GmailMsg): string => {
    const subjectHeader = m.payload && m.payload.headers && m.payload.headers.find(h => h.name === 'Subject');
    return (subjectHeader && subjectHeader.value) || '';
  };

  private static msgPeople = (m: GmailMsg): string => {
    return String(m.payload && m.payload.headers && m.payload.headers.filter(h => h.name === 'To' || h.name === 'From').map(h => h.value!).filter(h => !!h).join(','));
  };

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
    return DATA[this.acct].messages.find(m => m.id === id);
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

  public searchMessages = (q: string) => {
    const subject = (q.match(/subject: "([^"]+)"/) || [])[1];

    if (subject) {
      // if any subject query found, all else is ignored
      // messages just filtered by subject
      return this.searchMessagesBySubject(subject);
    }
    const excludePeople = (q.match(this.exludePplSearchQuery) || []).map(e => e.replace(/^(-from|-to):/, '').replace(/"/g, ''));
    q = q.replace(this.exludePplSearchQuery, ' ');
    const includePeople = (q.match(this.includePplSearchQuery) || []).map(e => e.replace(/^(from|to):/, '').replace(/"/g, ''));
    if (includePeople.length || excludePeople.length) {
      // if any to,from query found, all such queries are collected
      // no distinction made between to and from, just searches headers
      // to: and from: are joined with OR
      // -to: and -from: are joined with AND
      // rest of query ignored
      return this.searchMessagesByPeople(includePeople, excludePeople);
    }
    return [];
  };

  public addMessage = (raw: string, mimeMsg: ParsedMail) => {
    const id = `msg_id_${lousyRandom()}`;

    // fix raw for iOS parser
    const decodedRaw = Buffer.from(raw, 'base64').toString().replace(/sinikael-\?=/g, 'sinikael-=');
    const rawBase64 = Buffer.from(decodedRaw).toString('base64');

    const msg = new GmailMsg({ labelId: 'SENT', id, raw: rawBase64, mimeMsg });
    DATA[this.acct].messages.unshift(msg);
  };

  public deleteThread = (threadId: string) => {
    DATA[this.acct].messages = DATA[this.acct].messages.filter(m => m.threadId != threadId);
  }

  public addDraft = (id: string, raw: string, mimeMsg: ParsedMail) => {
    const draft = new GmailMsg({ labelId: 'DRAFT', id, raw, mimeMsg });
    const index = DATA[this.acct].drafts.findIndex(d => d.id === draft.id);
    if (index === -1) {
      DATA[this.acct].drafts.push(draft);
    } else {
      DATA[this.acct].drafts[index] = draft;
    }
  };

  public getDraft = (id: string): GmailMsg | undefined => {
    return DATA[this.acct].drafts.find(d => d.id === id);
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
    for (const thread of this.getMessagesAndDrafts().
      filter(m => labelIds.length ? (m.labelIds || []).some(l => labelIds.includes(l)) : true).
      filter(m => subject ? GoogleData.msgSubject(m).toLowerCase().includes(subject) : true).
      map(m => ({ historyId: m.historyId, id: m.threadId!, snippet: `MOCK SNIPPET: ${GoogleData.msgSubject(m)}` }))) {
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

  private searchMessagesBySubject = (subject: string) => {
    subject = subject.trim().toLowerCase();
    const messages = DATA[this.acct].messages.filter(m => GoogleData.msgSubject(m).toLowerCase().includes(subject));
    return messages;
  };

  private searchMessagesByPeople = (includePeople: string[], excludePeople: string[]) => {
    includePeople = includePeople.map(person => person.trim().toLowerCase());
    excludePeople = excludePeople.map(person => person.trim().toLowerCase());
    return DATA[this.acct].messages.filter(m => {
      const msgPeople = GoogleData.msgPeople(m).toLowerCase();
      let shouldInclude = false;
      let shouldExclude = false;
      if (includePeople.length) { // filter who to include
        for (const includePerson of includePeople) {
          if (msgPeople.includes(includePerson)) {
            shouldInclude = true;
            break;
          }
        }
      } else { // do not filter who to include - include any
        shouldInclude = true;
      }
      if (excludePeople.length) { // filter who to exclude
        for (const excludePerson of excludePeople) {
          if (msgPeople.includes(excludePerson)) {
            shouldExclude = true;
            break;
          }
        }
      } else { // don't exclude anyone
        shouldExclude = false;
      }
      return shouldInclude && !shouldExclude;
    });
  };

}
