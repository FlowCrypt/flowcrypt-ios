/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { GoogleConfig, MockConfig } from '../../lib/configuration-types';
import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { GoogleData } from './google-data';
import Parse from '../../util/parse';
import { isDelete, isGet, isPost, isPut, parseResourceId } from '../../lib/mock-util';
import { oauth } from '../../lib/oauth';
import { GoogleMockAccountEmail } from './google-messages';

// type DraftSaveModel = { message: { raw: string, threadId: string } };
type LabelsModifyModel = { addLabelIds: string[], removeLabelIds: string[] }
interface BatchModifyInterface {
  ids: string[];
  addLabelIds: string[];
  removeLabelIds: string[];
}

export const getMockGoogleEndpoints = (
  mockConfig: MockConfig,
  googleConfig?: GoogleConfig
): HandlersDefinition => {

  return {
    '/o/oauth2/auth': async ({ query: { client_id, nonce, response_type, state, redirect_uri, scope, login_hint } }, req) => {
      if (isGet(req) && client_id === oauth.clientId && response_type === 'code' && state && redirect_uri === oauth.redirectUri && scope) { // auth screen
        if (!login_hint) {
          return oauth.renderText('choose account with login_hint');
        } else {
          return oauth.generateAuthTokensAndRedirectUrl(login_hint as GoogleMockAccountEmail, state, nonce);
        }
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/token': async ({ query: { grant_type, refresh_token, client_id, code } }, req) => {
      if (isPost(req) && grant_type === 'authorization_code' && code && client_id === oauth.clientId) { // auth code from auth screen gets exchanged for access and refresh tokens
        return oauth.getRefreshTokenResponse(code);
      } else if (isPost(req) && grant_type === 'refresh_token' && refresh_token && client_id === oauth.clientId) { // here also later refresh token gets exchanged for access token
        return oauth.getAccessTokenResponse(refresh_token);
      }
      throw new Error(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/oauth2/v2/userinfo': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const profile = (await GoogleData.withInitializedData(acct, googleConfig)).getUserInfo();
        return profile;
      }
      throw new Error(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/v1/people:searchContacts': async ({ query: { query } }, req) => {
      if (!isGet(req)) {
        throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
      }

      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      const contacts = (await GoogleData.withInitializedData(acct, googleConfig)).searchContacts(query);
      const results = contacts.map(contact => {
        return {
          person: {
            emailAddresses: [
              { metadata: { primary: true }, value: contact.email }
            ],
            names: [
              { metadata: { primary: true }, displayName: contact.name }
            ]
          }
        }
      })
      return { results: results };
    },
    '/v1/otherContacts:search': async (_, req) => {
      if (!isGet(req)) {
        throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
      }

      return {}
    },
    '/gmail/v1/users/me/settings/sendAs': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const aliases = (await GoogleData.withInitializedData(acct, googleConfig)).getAliases();
        return { sendAs: aliases };
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/messages': async (parsedReq, req) => { // search messages
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const labelIds = [parsedReq.query.labelIds].filter(i => i);
        const msgs = (await GoogleData.withInitializedData(acct, googleConfig)).getMessages(labelIds, parsedReq.query.q);
        return { messages: msgs.map(({ id, threadId }) => ({ id, threadId })), resultSizeEstimate: msgs.length };
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/messages/?': async (parsedReq, req) => { // get msg or attachment
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const id = parseResourceId(req.url!);
        const data = await GoogleData.withInitializedData(acct, googleConfig);
        if (req.url!.includes('/attachments/')) {
          const attachment = data.getAttachment(id);
          if (attachment) {
            return attachment;
          }
          throw new HttpErr(`MOCK attachment not found for ${acct}: ${id}`, Status.NOT_FOUND);
        }
        const msg = data.getMessage(id);
        if (msg) {
          return GoogleData.fmtMsg(msg, parsedReq.query.format);
        }
        throw new HttpErr(`MOCK Message not found for ${acct}: ${id}`, Status.NOT_FOUND);
      } else if (isPost(req)) {
        const urlData = req.url!.split('/');
        const id = urlData[urlData.length - 2];
        const body = parsedReq.body as LabelsModifyModel;
        const data = await GoogleData.withInitializedData(acct, googleConfig);
        data.updateMessageLabels(body.addLabelIds, body.removeLabelIds, id);
        const msg = data.getMessage(id);
        if (msg) {
          return GoogleData.fmtMsg(msg, parsedReq.query.format);
        }
        throw new HttpErr(`MOCK Message not found for ${acct}: ${id}`, Status.NOT_FOUND);
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/labels': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        return { labels: (await GoogleData.withInitializedData(acct, googleConfig)).getLabels() };
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/threads': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const threads = (await GoogleData.withInitializedData(acct, googleConfig)).getThreads([parsedReq.query.labelIds].filter(i => i), parsedReq.query.q); // todo: support arrays?
        return { threads, resultSizeEstimate: threads.length };
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/threads/?': async (parsedReq, req) => {
      if (req.url!.match(/\/modify$/)) {
        return {};
      }
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const id = parseResourceId(req.url!);
        const msgs = (await GoogleData.withInitializedData(acct, googleConfig)).getMessagesAndDraftsByThread(id);
        if (!msgs.length) {
          const statusCode = id === '16841ce0ce5cb74d' ? 404 : 400; // intentionally testing missing thread
          throw new HttpErr(`MOCK thread not found for ${acct}: ${id}`, statusCode);
        }
        return { id, historyId: msgs[0].historyId, messages: msgs.map(m => GoogleData.fmtMsg(m, parsedReq.query.format)) };
      } else if (isPost(req)) {
        const urlData = req.url!.split('/');
        const threadId = urlData[urlData.length - 2];
        const body = parsedReq.body as LabelsModifyModel;
        const data = await GoogleData.withInitializedData(acct, googleConfig);
        data.updateMessageLabels(body.addLabelIds, body.removeLabelIds, undefined, threadId);
        const msgs = data.getMessagesByThread(threadId).map(msg => {
          return GoogleData.fmtMsg(msg, parsedReq.query.format)
        });
        return msgs;
      } else if (isDelete(req)) {
        const id = parseResourceId(req.url!);
        const data = await GoogleData.withInitializedData(acct, googleConfig);
        data.deleteThread(id);
        return {}
      }
      return {}
    },
    '/gmail/v1/users/me/drafts': async () => {
      return {}
      // if (isPost(req)) {
      //   const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      //   const body = parsedReq.body as DraftSaveModel;
      //   if (body && body.message && body.message.raw && typeof body.message.raw === 'string') {
      //     if (body.message.threadId && !(await GoogleData.withInitializedData(acct, googleConfig)).getThreads().find(t => t.id === body.message.threadId)) {
      //       throw new HttpErr('The thread you are replying to not found', 404);
      //     }
      //     const decoded = await Parse.convertBase64ToMimeMsg(body.message.raw);
      //     if (!decoded.text?.startsWith('[flowcrypt:') && !decoded.text?.startsWith('(saving of this draft was interrupted - to decrypt it, send it to yourself)')) {
      //       throw new Error(`The "flowcrypt" draft prefix was not found in the draft. Instead starts with: ${decoded.text?.substring(0, 100)}`);
      //     }
      //     return {
      //       id: 'mockfakedraftsave', message: {
      //         id: 'mockfakedmessageraftsave',
      //         labelIds: ['DRAFT'],
      //         threadId: body.message.threadId
      //       }
      //     };
      //   }
      // }
      // throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/drafts/?': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);
      if (isGet(req)) {
        const id = parseResourceId(req.url!);
        const data = (await GoogleData.withInitializedData(acct, googleConfig));
        const draft = data.getDraft(id);
        if (draft) {
          return { id: draft.id, message: draft };
        }
        throw new HttpErr(`MOCK draft not found for ${acct} (draftId: ${id})`, Status.NOT_FOUND);
      } else if (isPut(req)) {
        const raw = (parsedReq.body as { message?: { raw?: string } })?.message?.raw;
        if (!raw) {
          throw new Error('mock Draft PUT without raw data');
        }
        const mimeMsg = await Parse.convertBase64ToMimeMsg(raw);
        if ((mimeMsg.subject || '').includes('saving and rendering a draft with image')) {
          const data = (await GoogleData.withInitializedData(acct, googleConfig));
          data.addDraft('draft_with_image', raw, mimeMsg);
        }
        if ((mimeMsg.subject || '').includes('RTL')) {
          const data = await GoogleData.withInitializedData(acct, googleConfig);
          data.addDraft(`draft_with_rtl_text_${mimeMsg.subject?.includes('rich text') ? 'rich' : 'plain'}`, raw, mimeMsg);
        }
        return {};
      } else if (isDelete(req)) {
        return {};
      }
      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/messages/send': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);

      if (isPost(req)) {
        const raw = (parsedReq.body as { raw: string })?.raw;
        const mimeMsg = await Parse.convertBase64ToMimeMsg(raw);
        const data = (await GoogleData.withInitializedData(acct, googleConfig));
        data.addMessage(raw, mimeMsg);
        return {}
      }

      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/messages/batchDelete': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);

      if (isPost(req)) {
        const ids = (parsedReq.body as { ids: string[] })?.ids;
        const data = (await GoogleData.withInitializedData(acct, googleConfig));
        data.deleteMessages(ids);
        return {}
      }

      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
    '/gmail/v1/users/me/messages/batchModify': async (parsedReq, req) => {
      const acct = oauth.checkAuthorizationHeaderWithAccessToken(req.headers.authorization);

      if (isPost(req)) {
        const requestBody = parsedReq.body as BatchModifyInterface;
        const data = (await GoogleData.withInitializedData(acct, googleConfig));
        data.updateBatchMessageLabels(requestBody.addLabelIds, requestBody.removeLabelIds, requestBody.ids);
        return {}
      }

      throw new HttpErr(`Method not implemented for ${req.url}: ${req.method}`);
    },
  };
}
