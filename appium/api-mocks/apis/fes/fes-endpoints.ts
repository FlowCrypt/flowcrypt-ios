/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { IncomingMessage } from 'http';
import { FesConfig, MockConfig } from '../../lib/configuration-types';
import { HandlersDefinition, HttpClientErr } from '../../lib/api';
import { MockJwt } from '../../lib/oauth';
import { expectContains, throwIfNotGetMethod } from '../../lib/mock-util';

export const getMockFesEndpoints = (
  mockConfig: MockConfig,
  fesConfig: FesConfig | undefined
): HandlersDefinition => {

  if (!fesConfig) {
    return {};
  }

  return {
    '/api/': async ({ }, req) => {
      throwIfNotGetMethod(req);
      return {
        "vendor": "Mock",
        "service": "enterprise-server",
        "orgId": "standardsubdomainfes.test",
        "version": "MOCK",
        "apiVersion": 'v1',
      };
    },
    '/api/v1/client-configuration': async ({ }, req) => {
      throwIfNotGetMethod(req);
      return { clientConfiguration: fesConfig.clientConfiguration };
    },
    '/api/v1/message/new-reply-token': async ({ }, req) => {
      if (req.method === 'POST') {
        authenticate(req);
        return { 'replyToken': 'mock-fes-reply-token' };
      }
      throw new HttpClientErr('Not Found', 404);
    },
    '/api/v1/message': async ({ body }, req) => {
      // body is a mime-multipart string, we're doing a few smoke checks here without parsing it
      if (req.method === 'POST') {
        expectContains(body, '-----BEGIN PGP MESSAGE-----');
        expectContains(body, '"associateReplyToken":"mock-fes-reply-token"');
        expectContains(body, '"to":["to@example.com"]');
        expectContains(body, '"cc":[]');
        expectContains(body, '"bcc":["bcc@example.com"]');
        authenticate(req);
        expectContains(body, '"from":"user@disablefesaccesstoken.test:8001"');
        return { 'url': `${mockConfig}/message/FES-MOCK-MESSAGE-ID` };
      }
      throw new HttpClientErr('Not Found', 404);
    },
  };

}

const authenticate = (req: IncomingMessage): string => {
  const jwt = (req.headers.authorization || '').replace('Bearer ', '');
  if (!jwt) {
    throw new Error('Mock FES missing authorization header');
  }
  return MockJwt.parseEmail(jwt);
};