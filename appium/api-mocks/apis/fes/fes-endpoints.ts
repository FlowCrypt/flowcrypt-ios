/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { IncomingMessage } from 'http';
import { FesConfig, MockConfig } from '../../lib/configuration-types';
import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { MockJwt } from '../../lib/oauth';
import { expectContains, throwIfNotGetMethod } from '../../lib/mock-util';

export class FesHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return {
      // follows FES error response format
      code: this.statusCode,
      message: `message:${this.message}`,
      details: `details:${this.message}`,
    };
  };
}

export class FesWrongFormatHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return {
      wrongFieldError: {
        wrongFieldCode: this.statusCode,
        wrongFieldMessage: this.message,
      },
    };
  };
}

export class FesPlainHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return this.message;
  };
}

export const getMockFesEndpoints = (mockConfig: MockConfig, fesConfig: FesConfig | undefined): HandlersDefinition => {
  if (!fesConfig) {
    return {};
  }

  return {
    '/fes/api/': async ({}, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      throwIfNotGetMethod(req);
      return {
        vendor: 'Mock',
        service: 'external-service',
        orgId: 'standardsubdomainfes.test',
        version: 'MOCK',
        apiVersion: 'v1',
      };
    },
    '/fes/api/v1/client-configuration': async ({}, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      throwIfNotGetMethod(req);
      return { clientConfiguration: fesConfig.clientConfiguration || {} };
    },
    '/fes/api/v1/message/new-reply-token': async ({}, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      if (req.method === 'POST') {
        authenticate(req);
        return { replyToken: 'mock-fes-reply-token' };
      }
      throw new FesHttpErr('Not Found', Status.NOT_FOUND);
    },
    '/fes/api/v1/message': async ({ body }, req) => {
      throwErrorIfConfigSaysSo(fesConfig);
      // body is a mime-multipart string, we're doing a few smoke checks here without parsing it
      if (req.method === 'POST') {
        expectContains(body, '-----BEGIN PGP MESSAGE-----');
        const match = String(body).match(/Content-Type: application\/json\s*\n\s*(\{.*\})/);

        if (!match) {
          throw new FesHttpErr('Bad request', Status.BAD_REQUEST);
        }
        const contentType = JSON.parse(match[0]);
        const { associateReplyToken, to, cc, bcc } = contentType;

        expect(associateReplyToken).toBe('mock-fes-reply-token');

        if (fesConfig.messageUploadCheck) {
          const { to: toCheck, cc: ccCheck, bcc: bccCheck } = fesConfig.messageUploadCheck;
          if (toCheck) expect(to).toBe(toCheck);
          if (ccCheck) expect(cc).toBe(ccCheck);
          if (bccCheck) expect(bcc).toBe(bccCheck);
        }

        return {
          url: `https://flowcrypt.com/shared-tenant-fes/message/6da5ea3c-d2d6-4714-b15e-f29c805e5c6a`,
          externalId: 'FES-MOCK-EXTERNAL-ID',
          emailToExternalIdAndUrl: {},
        };
      }
      throw new FesHttpErr('Not Found', Status.NOT_FOUND);
    },
  };
};

const throwErrorIfConfigSaysSo = (config: FesConfig) => {
  if (config.returnError) {
    switch (config.returnError.format) {
      case 'wrong-text':
        throw new FesPlainHttpErr(config.returnError.message, config.returnError.code);
      case 'wrong-json':
        throw new FesWrongFormatHttpErr(config.returnError.message, config.returnError.code);
      default:
        throw new FesHttpErr(config.returnError.message, config.returnError.code);
    }
  }
};

const authenticate = (req: IncomingMessage): string => {
  const jwt = (req.headers.authorization || '').replace('Bearer ', '');
  if (!jwt) {
    throw new Error('Mock FES missing authorization header');
  }
  return MockJwt.parseEmail(jwt);
};
