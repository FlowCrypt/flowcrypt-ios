/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { HttpErr, Status, TemporaryRedirectHttpErr } from './api';

import { Buf } from '../core/buf';
import { Str } from '../core/common';
import { GoogleMockAccountEmail } from 'api-mocks/apis/google/google-messages';

const authURL = 'https://localhost:8001';

export class OauthMock {

  public clientId = '679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc.apps.googleusercontent.com';
  public expiresIn = 2 * 60 * 60; // 2hrs in seconds
  public redirectUri = 'com.googleusercontent.apps.679326713487-5r16ir2f57bpmuh2d6dal1bcm9m1ffqc:/oauthredirect';

  private authCodesByAcct: { [acct: string]: string } = {};
  private refreshTokenByAuthCode: { [authCode: string]: string } = {};
  private accessTokenByRefreshToken: { [refreshToken: string]: string } = {};
  private acctByAccessToken: { [acct: string]: GoogleMockAccountEmail } = {};
  private acctByIdToken: { [acct: string]: string } = {};
  private issuedIdTokensByAcct: { [acct: string]: string[] } = {};
  private nonceByAcct: { [acct: string]: string } = {};

  public renderText = (text: string) => {
    return this.htmlPage(text, text);
  }

  public generateAuthTokensAndRedirectUrl = (acct: GoogleMockAccountEmail, state: string, nonce: string) => {
    const authCode = `mock-auth-code-${acct.replace(/[^a-z0-9]+/g, '')}`;
    const refreshToken = `mock-refresh-token-${acct.replace(/[^a-z0-9]+/g, '')}`;
    const accessToken = `mock-access-token-${acct.replace(/[^a-z0-9]+/g, '')}`;
    this.authCodesByAcct[acct] = authCode;
    this.refreshTokenByAuthCode[authCode] = refreshToken;
    this.accessTokenByRefreshToken[refreshToken] = accessToken;
    this.acctByAccessToken[accessToken] = acct;
    this.nonceByAcct[acct] = nonce;

    const redirectUri = `${this.redirectUri}?code=${encodeURIComponent(authCode)}&state=${encodeURIComponent(state)}&authuser=0&prompt=consent&nonce=${encodeURIComponent(nonce)}`;
    throw new TemporaryRedirectHttpErr(redirectUri);
  }

  public getRefreshTokenResponse = (code: string) => {
    const refresh_token = this.refreshTokenByAuthCode[code];
    const access_token = this.getAccessToken(refresh_token);
    const acct = this.acctByAccessToken[access_token];
    const id_token = this.generateIdToken(acct);
    const nonce = this.nonceByAcct[acct];
    const scope = 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://mail.google.com/ openid https://www.googleapis.com/auth/contacts https://www.googleapis.com/auth/contacts.other.readonly';
    return { access_token, refresh_token, expires_in: this.expiresIn, id_token: id_token, nonce: nonce, token_type: 'Bearer', scope: scope }; // guessed the token_type
  }

  public getAccessTokenResponse = (refreshToken: string) => {
    try {
      const access_token = this.getAccessToken(refreshToken);
      const acct = this.acctByAccessToken[access_token];
      const id_token = this.generateIdToken(acct);
      const nonce = this.nonceByAcct[acct];
      return { access_token, expires_in: this.expiresIn, id_token, token_type: 'Bearer', nonce: nonce };
    } catch (e) {
      throw new HttpErr('invalid_grant', Status.BAD_REQUEST);
    }
  }

  public checkAuthorizationHeaderWithAccessToken = (authorization: string | undefined) => {
    if (!authorization) {
      throw new HttpErr('Missing mock bearer authorization header', Status.UNAUTHORIZED);
    }
    const accessToken = authorization.replace(/^Bearer /, '');
    const acct = this.acctByAccessToken[accessToken];
    if (!acct) {
      throw new HttpErr('Invalid mock auth token', Status.UNAUTHORIZED);
    }
    return acct;
  }

  /**
   * As if a 3rd party was evaluating it, such as key manager
   */
  public checkAuthorizationHeaderWithIdToken = (authorization: string | undefined) => {
    if (!authorization) {
      throw new HttpErr('Missing mock bearer authorization header', Status.UNAUTHORIZED);
    }
    const accessToken = authorization.replace(/^Bearer /, '');
    const acct = this.acctByIdToken[accessToken];
    if (!acct) {
      throw new HttpErr('Invalid idToken token', Status.UNAUTHORIZED);
    }
    return acct;
  }

  public isIdTokenValid = (idToken: string) => { // we verify mock idToken by checking if we ever issued it
    const [, data,] = idToken.split('.');
    const claims = JSON.parse(Buf.fromBase64UrlStr(data).toUtfStr());
    return (this.issuedIdTokensByAcct[claims.email] || []).includes(idToken);
  }

  // -- private

  private generateIdToken = (email: string): string => {
    const nonce = this.nonceByAcct[email];
    const newIdToken = MockJwt.new(email, nonce, this.expiresIn);
    if (!this.issuedIdTokensByAcct[email]) {
      this.issuedIdTokensByAcct[email] = [];
    }
    this.issuedIdTokensByAcct[email].push(newIdToken);
    this.acctByIdToken[newIdToken] = email;
    return newIdToken;
  }

  private getAccessToken(refreshToken: string): string {
    if (this.accessTokenByRefreshToken[refreshToken]) {
      return this.accessTokenByRefreshToken[refreshToken];
    }
    throw new HttpErr('Wrong mock refresh token', Status.UNAUTHORIZED);
  }

  private htmlPage = (title: string, content: string) => {
    return `<!DOCTYPE HTML><html><head><title>${title}</title></head><body>${content}</body></html>`;
  }
}

export class MockJwt {

  public static new = (email: string, nonce: string, expiresIn = 1 * 60 * 60): string => {
    const prefix = { "alg": "RS256", "kid": Str.sloppyRandom(40), "typ": "JWT" };
    const data = {
      at_hash: 'at_hash',
      exp: Math.round(Date.now() / 1000) + expiresIn,
      iat: Math.round(Date.now() / 1000),
      sub: 'sub',
      aud: oauth.clientId,
      azp: oauth.clientId,
      iss: authURL,
      name: 'First Last',
      picture: 'picture',
      locale: 'en',
      family_name: 'Last',
      given_name: 'First',
      email,
      email_verified: true,
      nonce: nonce
    };
    const newIdToken = `${Buf.fromUtfStr(JSON.stringify(prefix)).toBase64UrlStr()}.${Buf.fromUtfStr(JSON.stringify(data)).toBase64UrlStr()}.${Str.sloppyRandom(30)}`;
    return newIdToken;
  }

  public static parseEmail = (jwt: string): string => {
    const email = JSON.parse(Buf.fromBase64Str(jwt.split('.')[1]).toUtfStr()).email;
    if (!email) {
      throw new Error(`Missing email in MockJwt ${jwt}`);
    }
    return email; // eslint-disable-line @typescript-eslint/no-unsafe-return
  }

}

export const oauth = new OauthMock();
