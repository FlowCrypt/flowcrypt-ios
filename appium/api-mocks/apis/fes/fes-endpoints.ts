/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { IncomingMessage } from 'http';
import { FesConfig, MockConfig } from '../../lib/configuration-types';
import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { MockJwt } from '../../lib/oauth';
import { expectContains, throwIfNotGetMethod } from '../../lib/mock-util';

export class FesHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return { // follows FES error response format
      "code": this.statusCode,
      "message": `message:${this.message}`,
      "details": `details:${this.message}`
    }
  }
}

export class FesWrongFormatHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return {
      "wrongFieldError": {
        "wrongFieldCode": this.statusCode,
        "wrongFieldMessage": this.message,
      }
    }
  }
}

export class FesPlainHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return this.message
  }
}

export const getMockFesEndpoints = (
  mockConfig: MockConfig,
  fesConfig: FesConfig | undefined
): HandlersDefinition => {

  if (!fesConfig) {
    return {};
  }

  return {
    '/fes/api/': async ({ }, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      throwIfNotGetMethod(req);
      return {
        "vendor": "Mock",
        "service": "external-service",
        "orgId": "standardsubdomainfes.test",
        "version": "MOCK",
        "apiVersion": 'v1',
      };
    },
    '/fes/api/v1/client-configuration': async ({ }, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      throwIfNotGetMethod(req);
      return { clientConfiguration: fesConfig.clientConfiguration || {} };
    },
    '/fes/api/v1/message/new-reply-token': async ({ }, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      if (req.method === 'POST') {
        authenticate(req);
        return { 'replyToken': 'mock-fes-reply-token' };
      }
      throw new FesHttpErr('Not Found', Status.NOT_FOUND);
    },
    '/fes/api/v1/message': async ({ body }, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
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
      throw new FesHttpErr('Not Found', Status.NOT_FOUND);
    },
  };
}

const throwErrorIfConfigSaysSo = (config: FesConfig) => {
  if (config.returnError) {
    switch (config.returnError.format) {
      case "wrong-text":
        throw new FesPlainHttpErr(config.returnError.message, config.returnError.code);
      case "wrong-json":
        throw new FesWrongFormatHttpErr(config.returnError.message, config.returnError.code);
      default:
        throw new FesHttpErr(config.returnError.message, config.returnError.code);
    }
  }
}

const authenticate = (req: IncomingMessage): string => {
  const jwt = (req.headers.authorization || '').replace('Bearer ', '');
  if (!jwt) {
    throw new Error('Mock FES missing authorization header');
  }
  return MockJwt.parseEmail(jwt);
};