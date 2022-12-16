/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import * as https from 'https';
import * as http from 'http';
import { readFileSync } from 'fs';
import { oauth } from './oauth';

export type HandlersDefinition = Handlers<{ query: { [k: string]: string; }; body?: unknown; }, unknown>;

export enum Status {
  OK = 200,
  CREATED = 201,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  CONFLICT = 409, // conflicts with key on record - request needs to be verified
  SERVER_ERROR = 500,
  NOT_IMPLEMENTED = 501,
}

export type RequestHandler<REQ, RES> = (parsedReqBody: REQ, req: http.IncomingMessage) => Promise<RES>;
export type Handlers<REQ, RES> = { [request: string]: RequestHandler<REQ, RES> };

export class Api<REQ, RES> {

  public server: https.Server | http.Server;
  protected apiName: string;
  protected maxRequestSizeMb = 0;
  protected maxRequestSizeBytes = 0;
  protected throttleChunkMsUpload = 0;
  protected throttleChunkMsDownload = 0;

  constructor(
    apiName: string,
    protected handlerGetters: (() => Handlers<REQ, RES>)[],
    protected urlPrefix = '',
    useHttps = true
  ) {
    this.apiName = apiName;
    if (useHttps) {
      this.server = https.createServer({
        key: readFileSync('./api-mocks/mock-ssl-cert/key.pem.mock'),
        cert: readFileSync('./api-mocks/mock-ssl-cert/cert.pem.mock')
      }, this.serverRequestListener);
    } else {
      this.server = http.createServer(this.serverRequestListener);
    }
  }

  private serverRequestListener = (request: http.IncomingMessage, response: http.ServerResponse) => {
    const start = Date.now();
    this.handleReq(request, response).then(data => this.throttledResponse(response, data)).then(() => {
      try {
        this.log(Date.now() - start, request, response);
      } catch (e) {
        console.error(e);
        process.exit(1);
      }
    }).catch((e) => {
      response.setHeader('Access-Control-Allow-Origin', '*');
      response.setHeader('content-type', 'application/json');

      if (e instanceof TemporaryRedirectHttpErr) {
        response.writeHead(302, {
          Location: e.redirectUrl
        });
        response.write(Buffer.from(e.redirectUrl, "utf-8"));
      } else if (e instanceof HttpErr) {
        response.statusCode = e.statusCode;
        e.stack = undefined;
      } else {
        response.statusCode = Status.SERVER_ERROR;
        if (e instanceof Error && e.message.toLowerCase().includes('intentional error')) {
          // don't log this, intentional error
        } else {
          console.error('url:%s:%s', request.method, request.url?.replace(/\n|\r/g, ""), e);
        }
      }

      const formattedErr = this.fmtErr(e);
      response.end(formattedErr);

      try {
        this.log(Date.now() - start, request, response, formattedErr);
      } catch (e) {
        console.error('error logging req', e);
      }
    });
  }

  public listen = (port: number, host = '127.0.0.1', maxMb = 100): Promise<void> => {
    return new Promise((resolve, reject) => {
      try {
        this.maxRequestSizeMb = maxMb;
        this.maxRequestSizeBytes = maxMb * 1024 * 1024;
        this.server.listen(port, host);
        this.server.on('listening', () => {
          const address = this.server.address();
          const msg = `${this.apiName} listening on ${typeof address === 'object' && address ? address.port : address}`;
          console.log(msg);
          resolve();
        });
        this.server.on('error', (e) => {
          console.error('failed to start mock server', e);
          reject(e);
        });
      } catch (e) {
        console.error('exception when starting mock server', e);
        reject(e);
      }
    });
  }

  public close = (): Promise<void> => {
    return new Promise((resolve, reject) => this.server.close((err: Error) => err ? reject(err) : resolve()));
  }

  protected log = (ms: number, req: http.IncomingMessage, res: http.ServerResponse, errRes?: Buffer) => { // eslint-disable-line @typescript-eslint/no-unused-vars
    return undefined as void;
  }

  private getHandlers = (): Handlers<REQ, RES> => {
    let allHandlers: Handlers<REQ, RES> = {};
    for (const handlerGetter of this.handlerGetters) {
      allHandlers = { ...allHandlers, ...handlerGetter() }
    }
    return allHandlers;
  }

  protected handleReq = async (req: http.IncomingMessage, res: http.ServerResponse): Promise<Buffer> => {
    if (req.method === 'OPTIONS') {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Headers', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,POST,PUT,DELETE,OPTIONS');
      return this.fmtRes({});
    }
    const handler = this.chooseHandler(req);
    if (handler) {
      const parsedReqBody = this.parseReqBody(await this.collectReq(req), req);
      const handledRequest = await handler(parsedReqBody, req);
      return this.fmtHandlerRes(handledRequest, res);
    }
    if ((req.url === '/' || req.url === `${this.urlPrefix}/`) && (req.method === 'GET' || req.method === 'HEAD')) {
      res.setHeader('content-type', 'application/json');
      return this.fmtRes({ app_name: this.apiName });
    }
    if ((req.url === '/alive' || req.url === `${this.urlPrefix}/alive`) && (req.method === 'GET' || req.method === 'HEAD')) {
      res.setHeader('content-type', 'application/json');
      return this.fmtRes({ alive: true });
    }
    throw new HttpErr(`unknown MOCK path ${req.url}`, Status.BAD_REQUEST);
  }

  protected chooseHandler = (req: http.IncomingMessage): RequestHandler<REQ, RES> | undefined => {
    if (!req.url) {
      throw new Error('no url');
    }
    const handlers = this.getHandlers();
    if (req.url in handlers) { // direct handler name match
      return handlers[req.url];
    }
    const url = req.url.split('?')[0];
    if (url in handlers) { // direct handler name match - ignoring query
      return handlers[url];
    }
    // handler match where definition url ends with "/?" - incomplete path definition
    for (const handlerPathDefinition of Object.keys(handlers).filter(def => /\/\?$/.test(def))) {
      if (req.url.startsWith(handlerPathDefinition.replace(/\?$/, '')) && handlerPathDefinition in handlers) {
        return handlers[handlerPathDefinition];
      }
    }
    return undefined;
  }

  protected fmtErr = (e: Error): Buffer => {
    if (String(e).includes('invalid_grant')) {
      return Buffer.from(JSON.stringify({ "error": "invalid_grant", "error_description": "Bad Request" }));
    }
    if (!(e instanceof HttpErr)) {
      if (e instanceof Error) {
        const newErr = new HttpErr(e.message, Status.SERVER_ERROR)
        newErr.stack = e.stack;
        e = newErr;
      } else {
        e = new HttpErr("Non-error thrown in mock: " + String(e), Status.SERVER_ERROR);
      }
    }
    return Buffer.from(JSON.stringify((e as HttpErr).formatted()));
  }

  protected fmtHandlerRes = (handlerRes: RES, serverRes: http.ServerResponse): Buffer => {
    if (typeof handlerRes === 'string' && handlerRes.match(/^<!DOCTYPE HTML><html>/)) {
      serverRes.setHeader('content-type', 'text/html');
    } else if (typeof handlerRes === 'object' || (typeof handlerRes === 'string' && handlerRes.match(/^\{/) && handlerRes.match(/\}$/))) {
      serverRes.setHeader('content-type', 'application/json');
    } else if (typeof handlerRes === 'string') {
      serverRes.setHeader('content-type', 'text/plain');
    } else {
      throw new Error(`Don't know how to decide mock response content-type header`);
    }
    serverRes.setHeader('Access-Control-Allow-Origin', '*');

    return this.fmtRes(handlerRes);
  }

  protected fmtRes = (response: {} | string): Buffer => {
    if (response instanceof Buffer) {
      return response;
    } else if (typeof response === 'string') {
      return Buffer.from(response);
    }
    const json = JSON.stringify(response);
    return Buffer.from(json);
  }

  protected collectReq = (req: http.IncomingMessage): Promise<Buffer> => {
    return new Promise((resolve, reject) => {
      const body: Buffer[] = [];
      let byteLength = 0;
      req.on('data', (chunk: Buffer) => {
        byteLength += chunk.length;
        if (this.maxRequestSizeBytes && byteLength > this.maxRequestSizeBytes) {
          reject(new HttpErr(`Message over ${this.maxRequestSizeMb} MB`, Status.BAD_REQUEST));
        } else {
          body.push(chunk);
        }
        if (this.throttleChunkMsUpload && body.length > 2) {
          req.pause(); // slow down accepting data by a certain amount of ms per chunk
          setTimeout(() => req.resume(), this.throttleChunkMsUpload);
        }
      });
      req.on('end', () => {
        try {
          resolve(Buffer.concat(body));
        } catch (e) {
          reject(e);
        }
      });
    });
  }

  protected parseReqBody = (body: Buffer, req: http.IncomingMessage): REQ => {
    let parsedBody: string | undefined;
    if (body.length) {
      if (
        req.url!.startsWith('/upload/') || // gmail message send
        req.url!.startsWith('/api/message/upload') || // flowcrypt.com/api pwd msg
        (req.url!.startsWith('/attester/pub/') && req.method === 'POST') || // attester submit
        req.url!.startsWith('/api/v1/message') || // FES pwd msg
        req.url!.startsWith('/token') // gmail auth token
      ) {
        parsedBody = body.toString();
      } else {
        parsedBody = JSON.parse(body.toString());
      }
    }

    const query = req.url!.startsWith('/token') ? this.parseUrlQuery(body.toString()) : this.parseUrlQuery(req.url!);
    return { query: query, body: parsedBody } as unknown as REQ;
  }

  private throttledResponse = async (response: http.ServerResponse, data: Buffer) => {
    if (data.toString().startsWith(oauth.redirectUri)) {
      // send redirect for mobile app auth
      response.writeHead(302, {
        Location: data.toString()
      });
      response.write(data);
      response.end();
    } else {
      const chunkSize = 100 * 1024;
      for (let i = 0; i < data.length; i += chunkSize) {
        const chunk = data.slice(i, i + chunkSize);
        response.write(chunk);
        if (i > 0) {
          await this.sleep(this.throttleChunkMsDownload / 1000);
        }
      }

      response.end();
    }

  }

  private sleep = async (seconds: number) => {
    return await new Promise(resolve => setTimeout(resolve, seconds * 1000));
  }

  private parseUrlQuery = (url: string): { [k: string]: string } => {
    const queryIndex = url.indexOf('?');
    const queryStr = !queryIndex ? url : url.substring(queryIndex + 1);
    const valuePairs = queryStr.split('&');
    const params: { [k: string]: string } = {};
    for (const valuePair of valuePairs) {
      if (valuePair) {
        const equalSignSeparatedParts = valuePair.split('=');
        params[equalSignSeparatedParts.shift()!] = decodeURIComponent(equalSignSeparatedParts.join('='));
      }
    }
    return params;
  }

}

export class HttpErr extends Error {
  constructor(message: string, public statusCode: number = 400) {
    super(message);
  }
  public formatted = (): unknown => {
    return {
      "mockError": this.message,
      "mockStack": this.stack || "no stack",
      "noFormatter": "if you wanted a different error format, subclass from HttpErr and add a formatter",
    }
  }
}

export class TemporaryRedirectHttpErr extends Error {
  public redirectUrl: string;

  constructor(redirectUrl: string) {
    super();
    this.redirectUrl = redirectUrl;
  }
}
