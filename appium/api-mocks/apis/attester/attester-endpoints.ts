/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { Dict } from '../../core/common';
import { isPost, isGet } from '../../lib/mock-util';
import { oauth } from '../../lib/oauth';
import { AttesterConfig, MockConfig } from '../../lib/configuration-types';

export class AttesterErr extends HttpErr {
  public formatted = (): unknown => {
    return {
      // follows Attester error format
      error: {
        code: this.statusCode,
        message: this.message,
      },
    };
  };
}

export const MOCK_ATTESTER_LAST_INSERTED_PUB: { [email: string]: string } = {};

export const getMockAttesterEndpoints = (
  mockConfig: MockConfig,
  attesterConfig: AttesterConfig | undefined,
): HandlersDefinition => {
  if (!attesterConfig) {
    return {};
  }

  return {
    '/attester/pub/?': async ({ body }, req) => {
      const email = req.url!.split('/').pop()!.toLowerCase().trim();
      throwErrorIfConfigSaysSo(attesterConfig);
      if (isGet(req)) {
        const pubkey = (attesterConfig.servedPubkeys || {})[email];
        if (pubkey) {
          return pubkey;
        }
        throw new AttesterErr('Pubkey not found on mock', 404);
      } else if (isPost(req)) {
        if (attesterConfig.enableSubmittingPubkeys !== true) {
          throw new AttesterErr('Mock Attester received unexpected pubkey submission', 405);
        }
        oauth.checkAuthorizationHeaderWithIdToken(req.headers.authorization);
        if (!(body as string).includes('-----BEGIN PGP PUBLIC KEY BLOCK-----')) {
          throw new AttesterErr(`Bad public key format`, 400);
        }
        MOCK_ATTESTER_LAST_INSERTED_PUB[email] = body as string;
        return 'Saved'; // 200 OK
      } else {
        throw new AttesterErr(`Not implemented: ${req.method}`, Status.BAD_REQUEST);
      }
    },
    '/attester/welcome-message': async ({ body }, req) => {
      throwErrorIfConfigSaysSo(attesterConfig);

      if (!attesterConfig.enableTestWelcome) {
        throw new AttesterErr('Mock Attester received unexpected /test/welcome request', 405);
      }
      if (!isPost(req)) {
        throw new AttesterErr(`Wrong method: ${req.method}`, Status.BAD_REQUEST);
      }
      const { email, pubkey } = body as Dict<string>;
      if (email.includes('@')) {
        throw new AttesterErr(`Bad email format`, 400);
      }
      if (pubkey.includes('-----BEGIN PGP PUBLIC KEY BLOCK-----')) {
        throw new AttesterErr(`Bad public key format`, 400);
      }
      return { sent: true };
    },
  };
};
const throwErrorIfConfigSaysSo = (config: AttesterConfig) => {
  if (config.returnError) {
    throw new AttesterErr(config.returnError.message, config.returnError.code);
  }
};

export const attesterPublicKeySamples = {
  valid: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: CryptUP 3.2.0 Easy Gmail Encryption https://cryptup.org
Comment: Seamlessly send, receive and search encrypted email

xsBNBFU0WMgBCACZSzijeN4YozhjmHU7BGWzW7ZbY6GGtJinByt8OnEnQ9TX
9zrAxbyr0grPE4On7nd3uepwNxJbk5LlaCwHNkpX39xKgDgCskRO9CfeqOIO
4l5Wjj4XldrgLSOGJe8Vmimo9UKmqsP5v8fR3mMyIqQbtE4G+Vq/J9A3uabr
f0XYVsBdBvVoJkQ83gtQrZoTA/zihNmtLXH9pTwtX8FJcqgFK6RgvfAh2jCz
DhT+reI50ZcuHRvVRxvrL172DFSQsLSdj8PcewS1J89knH4sjjBC/kwbLa0n
tod/gBPWw/uetaOJna43wNueUKKOl2kAXE4sw6ESIrlFDynJ4g05T9yxABEB
AAHNIlRvbSBKYW1lcyBIb2x1YiA8dG9tQGJpdG9hc2lzLm5ldD7CwFwEEAEI
ABAFAlU0WM8JEA1WiOvzECvnAAAB4gf8DaIzZACUqkGEoI19HyBPtcrJT4mx
hKZ/Wts0C6TGj/OQXevDI+h2jQTYf8+fOqCdQev2Kwh/8mQV6wQqmN9uiVXO
5F4vAbWNfEve6mCVB5gi296mFf6kx04xC7VVYAJ3FUR72BplE/0+cwv9Nx2r
Jh3QGFhoPaFMPtCAk0TgKcO0UkcBwXNzAV5Pgz0MT1COTWBXEej4yOrqdWoP
A6fEpV8aLaFnAt+zh3cw4A7SNAO9omGAUZeBl4Pz1IlN2lC2grc2zpqoxo8o
3W49JYTfExeCNVWhlSU74f6bpN6CMdSdrh5phOr+ffQQhEhkNblUgSZe6tKa
VFI1MhkJ6Xhrug==
=+de8
-----END PGP PUBLIC KEY BLOCK-----`,
  keyOlderVersion: `-----BEGIN PGP PUBLIC KEY BLOCK-----

xjMEYd8pKhYJKwYBBAHaRw8BAQdAXQ9bBzlYPwy3mQD5MIQSkuOyEomESHHo
AAiUi0enB77NKFVwZGF0aW5nIGtleSA8dXBkYXRpbmcua2V5QGV4YW1wbGUu
dGVzdD7CeAQQFgoAIAUCYd8pKgYLCQcIAwIEFQgKAgQWAgEAAhkBAhsDAh4B
AAoJEMfJkMGi6njd9HUA/0ZdZaaOFy0hM+GpEnzK+A/G3bLe9Kulh4jT8+4j
JqcKAP0V+pga+B1v98aeF8cRlgQPEyWtYUqZLcDLBQ6r3BEfDM44BGHfKSoS
CisGAQQBl1UBBQEBB0BPkVSyVsZ+vsF4e4NbVsq/YNjqL0JQI+t6OHc5YxJS
SgMBCAfCYQQYFggACQUCYd8pKgIbDAAKCRDHyZDBoup43Y+gAQDSVD/EDqCE
dSL33ptMlhwRCKHGiKcVmKwucxYkk6apFQEA018565fZcvtb339L2s/IIxLs
4621FX8Sy6kpR7mAzQo=
=3UnZ
-----END PGP PUBLIC KEY BLOCK-----`,
  keyNewerVersion: `-----BEGIN PGP PUBLIC KEY BLOCK-----

xjMEYd8pKhYJKwYBBAHaRw8BAQdAXQ9bBzlYPwy3mQD5MIQSkuOyEomESHHo
AAiUi0enB77NKFVwZGF0aW5nIGtleSA8dXBkYXRpbmcua2V5QGV4YW1wbGUu
dGVzdD7CeAQQFgoAIAUCYd8pKgYLCQcIAwIEFQgKAgQWAgEAAhkBAhsDAh4B
AAoJEMfJkMGi6njd9HUA/0ZdZaaOFy0hM+GpEnzK+A/G3bLe9Kulh4jT8+4j
JqcKAP0V+pga+B1v98aeF8cRlgQPEyWtYUqZLcDLBQ6r3BEfDM44BGHfKSoS
CisGAQQBl1UBBQEBB0BPkVSyVsZ+vsF4e4NbVsq/YNjqL0JQI+t6OHc5YxJS
SgMBCAfCYQQYFggACQUCYd8pKgIbDAAKCRDHyZDBoup43Y+gAQDSVD/EDqCE
dSL33ptMlhwRCKHGiKcVmKwucxYkk6apFQEA018565fZcvtb339L2s/IIxLs
4621FX8Sy6kpR7mAzQrOOARh3yuYEgorBgEEAZdVAQUBAQdAglzBCJCRj29J
THYvVGaNESiiVKmyrTEnXonGUS58TwMDAQgHwmEEGBYIAAkFAmHfK5gCGwwA
CgkQx8mQwaLqeN3PWwD9ErvC+ufnX0O2AmZDz67QfFH6tA1t1/wUEHgzBXEe
gc8BAMaYm3AlSGbX1rJYgUtCWukkLuURdECIzerG2UuP87ID
=dQen
-----END PGP PUBLIC KEY BLOCK-----`,
};
