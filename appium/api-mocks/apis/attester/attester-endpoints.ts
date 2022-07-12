/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { HandlersDefinition, HttpErr, Status } from '../../lib/api';
import { Dict } from '../../core/common';
import { isPost, isGet } from '../../lib/mock-util';
import { oauth } from '../../lib/oauth';
import { AttesterConfig, MockConfig } from '../../lib/configuration-types';

export class AttesterErr extends HttpErr {
  public formatted = (): unknown => {
    return { // follows Attester error format
      error: {
        "code": this.statusCode,
        "message": this.message,
      }
    }
  }
}

export const MOCK_ATTESTER_LAST_INSERTED_PUB: { [email: string]: string } = {};

export const getMockAttesterEndpoints = (
  mockConfig: MockConfig,
  attesterConfig: AttesterConfig | undefined
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
    '/attester/test/welcome': async ({ body }, req) => {
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
}
const throwErrorIfConfigSaysSo = (config: AttesterConfig) => {
  if (config.returnError) {
    throw new AttesterErr(config.returnError.message, config.returnError.code);
  }
}

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
  expired: `-----BEGIN PGP PUBLIC KEY BLOCK-----

xsBNBGANSYYBCACkVfVUKS9ura0KSiRu6i4bC0mEpwOjuYotor1d1NciysN977UMKQw1uux0GIZz
3PvJUL4Ij77eyF5wxOueOwqON/LHunqnufvES9zj2BgQLwfE5d7gXp0IjQqWEg4YfSkTNIwzP67R
qDbvW4E7XScLY1BYutrZhq53rzXurON9eftFi2ScW4/Pja2eCah5bMxFqoINRGFYJwK6Z6rD1h2+
/w5s9Ir+qELUKxIYtwfp2Uf3uTDnT4BRFPcuNh9rXLPpXprTjGe2cZ6i9ENzMj0dTlU8kqvTyhPm
BReZZZcUe5teVyfbLXmz/nQCnxnuH/e8LDeQ5TC6knTFd8d9gTI7ABEBAAHNHmV4cGlyZWQub24u
YXR0ZXN0ZXJAZG9tYWluLmNvbcLAjwQTAQgAORYhBBr54+QEmYDLPhttjC90yktngnCgBQJgDUmL
BQkAAAA8AhsDBQsJCAcCBhUICQoLAgUWAgMBAAAKCRAvdMpLZ4JwoLb0B/0cFAn266wKMNSq556G
ldLCLDpPrMaKy6r3qsiG/Y3otvnn+iBLqkuEo7P9XmfQooiplpUxLnmiBmGxlVmUcNMBh15Z7GXP
cj4fas++H1sjAbF6mPqhggIsxGcnk9YjbZC+GaDzKp5BKgDUUIitsYzSENdADqeL6SQixSMWAiGA
CiOQ8mnriH/CGb1XW76YVjYa5fK2OqflQj+l5IiJ4gqWuHpYs5zR24tnxIiv5UtvxglahV8Tugdf
KfjnkfYbJEwxyUGzXNtmqhsrhoSWaYbrqjRqNolnFP6hr5NlVVNA9XNWLhWd0HdhzgJWYvd+ukLE
eTY/IvQlyIVMV9nqQqOVzsBNBGANSYwBCADFzPusdjjO0zcI/7sfgUHk/XmPawR6WIhzTHaM38Pg
1woaXZt0oSU6K2OSKwYRnuVGM0zbjhhICPhtAo3m26h4LojPlM1Dnp+U/p9hXVFa7MPtlUupfhZt
9Ip4nNLWyYhQrSAI73InVtJvYQbQU/t7or+twrXZJqAPIqMBQ+pkYab8+bOfdY+/QoHM7SKyvggg
6E+4fw9IwwaoZpxcbc2Wbcn1LpaF2xZUq0kWxtQ86b6rMQWbNgfs4xVUKAeP74SINM5iYDV4qjD0
KTTzAmn/rlBbvwP2r7SX1gmismLJYDJCpZrYdJEMOMhfXBQaz+0rlHIT6YIyr1mpLecJzIXRABEB
AAHCwHwEGAEIACYWIQQa+ePkBJmAyz4bbYwvdMpLZ4JwoAUCYA1JkQUJAAAAPAIbDAAKCRAvdMpL
Z4JwoGmXB/97g6/UkdVtBv5bP1V7JZpxEo31Q0S3dZR6pMVaEpVgtksSIcO2i9PdCZhYZ9noRkdO
BpSNkgVOzk6/WvpVBl8TZ7bpWa7ux6ExiJLKKjWSHnJJ3SkviARSrAmDfvDCxKh3duEmjsmBy/r0
ugFu0E2D/Oxqa6ZUv7swwx8kuq7/UchZLQQCiKCGosRqiApqhp2ze/CNzeD/na+q0yvT6pFFDjGl
82Yrr1oqCyZZedSFSLelVqBJ8FkyJlqN3J9Q3M5rEp5vcRqGOHxfO5j2Gb88mmmtnWnBzRPPX8CB
DDF85HtNOR10V1aJrfE7F6e3QTzu5SZBjDPi5vVcbtK72eyd
=o0Ib
-----END PGP PUBLIC KEY BLOCK-----`,
  expiredFlowcrypt: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYW8A6BYJKwYBBAHaRw8BAQdAcdakYLj0UoCYB+atCEkNjUP7SSD7r7iq
VRkrZjqpzafNI2V4cGlyZWQga2V5IDxleHBpcmVkQGZsb3djcnlwdC5jb20+
wngEExYKACAFAmFvAOgCGwMFFgIDAQAECwkIBwUVCgkICwIeAQIZAQAKCRAv
B68u47oY6BfyAP4/fDJuxAsvo8XQ3N4ovA9D/H7VyTnu89ku8pKIQImhgwEA
0Mkinhg3eYtc5eG8BVHXZyFNte+JIKLwJPxv3NZ6KQXCfgQTFgoAJgIbAwUW
AgMBAAQLCQgHBRUKCQgLAh4BAhkBBQJhbwE3BYkAAayXAAoJEC8Hry7juhjo
92sA/AovlTncTQHb2+JOnha3WCPraiiUjdZTPlVksz0yZTMlAQCfI0E0WnKV
1W9uXaBZMTkSzzv0BTtSr9MNAMhl+52HB844BGFvAOgSCisGAQQBl1UBBQEB
B0Ace7wKz8QEpIf3B17RiX185nwA0nUe8Ng+SYrT/inxXQMBCAfCdQQYFgoA
HQUCYW8A6AIbDAUWAgMBAAQLCQgHBRUKCQgLAh4BAAoJEC8Hry7juhjo4z8B
AIxiBFwVSeC80FX+DrBEPH2tZURnoJnqNzcf/Hz03gp5AP90vsuJHXLyd+xx
nGjRZ3go4jom7MU77w5GtHuvfObRC8J7BBgWCgAjAhsMBRYCAwEABAsJCAcF
FQoJCAsCHgEFAmFvATcFiQABrJcACgkQLwevLuO6GOgHPgEAhfcecP1GG/dp
1sbpsBfwJJKK+bJhiyYlB5izgpxslk4A/0wNujSC9MOusPziwgebviKxZQXP
T4gbgCg6JBONQ8MM
=Cabr
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
  revoked: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYW8BThYJKwYBBAHaRw8BAQdAYtEoS4d+3cwQWXcs3lvMQueypexTYai7
uXQmxqyOoKrCjAQgFgoAHQUCYW8CLBYhBDkxt0E9uy+mDO+Fzl8Vl4kQoXgK
ACEJEF8Vl4kQoXgKFiEEOTG3QT27L6YM74XOXxWXiRCheAqk5AEApn8X3Oe7
EFgdfo5lkgh6ubpmgyRUpfYHkQE2/S6K+T0BAPGs2py515aUVAgiRy7bJuoY
DKKbOPL1Npd0bgenKgMGzRVyZXZvZWtkQGZsb3djcnlwdC5jb23CXgQTFgoA
BgUCYW8BawAKCRBfFZeJEKF4ChD/AP9gdm4riyAzyGhD4P8ZGW3GtREk56sW
RBB3A/+RUX+qbAEA3FWCs2bUl6pmasXP8QAi0/zoruZiShR2Y2mVAM3T1ATN
FXJldm9rZWRAZmxvd2NyeXB0LmNvbcJeBBMWCgAGBQJhbwFrAAoJEF8Vl4kQ
oXgKecoBALdrD8nkptLlT8Dg4cF+3swfY1urlbdEfEvIjN60HRDLAP4w3qeS
zZ+OyuqPFaw7dM2KOu4++WigtbxRpDhpQ9U8BQ==
=bMwq
-----END PGP PUBLIC KEY BLOCK-----`,
  robot: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYsM6KRYJKwYBBAHaRw8BAQdADKgbtPI+a+2y/fDh5CxVqvc6wbSvmMe3
TcSHCT+Go/XNJUZsb3dDcnlwdCBSb2JvdCA8cm9ib3RAZmxvd2NyeXB0LmNv
bT7CdwQQFgoAHwUCYsM6KQYLCQcIAwIEFQgKAgMWAgECGQECGwMCHgEACgkQ
9OtwbUUrhUR8qAEA802mHSF6vtppMqUFBAKduJX8LmrKtX8FssMcq/9HTT8A
/R615Nm1seyrNuC2J2TdTqYG5O2i6fUWlqGldOzrwpYOzjgEYsM6KRIKKwYB
BAGXVQEFAQEHQJ0nskrHuPK0drUMJOo3j3VPVxdEDudw1mlaLowJfl0TAwEI
B8JhBBgWCAAJBQJiwzopAhsMAAoJEPTrcG1FK4VEh4YBALYL4hcYE8/nUgHd
i0Bd7uutnnkRdCDPTvY5ub4ZDrHGAQCFIYc+Mp6zZdR1s/3kIpjrcg6mOtmj
7Xox/a0FLLQsCQ==
=+AGT
-----END PGP PUBLIC KEY BLOCK-----`,
};
