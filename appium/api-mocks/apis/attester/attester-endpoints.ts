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
  anotherValid: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: OpenPGP.js v3.0.5
Comment: https://openpgpjs.org

xsBNBFskt/ABCAD0N+Y+ZavNGwRif9vkjcHxmvWkkqBO+pA1KanPUftoi2b/
zMErfl+4P6xe+KpDS97W/BqBGKP7bzN08XSkqyROhv/lroofXgu1WSJ53znf
bRGiRmOjIntBX7iSKecSh9zcgjBRK6xnhoaXxUhCwp8ZsxapMRSwQmlXU6WQ
4XAI4JhtZVpBUtbeUW0/+4KRObmj9Dy+4nnNFFBubBrHV0F7FmkJkvksvkNL
4awmTFbfPE8vkapoDi1hFzMbWoYvEPLmv/HTRcqjPZASLr7fXG+AOefE8uJA
L++Zs0jw2ukrk9KHk3q70ii61CUz9zODCXzeoWQMNTUHoZFuhzawCFe1ABEB
AAHNT2Zsb3djcnlwdC5jb21wYXRpYmlsaXR5QHByb3Rvbm1haWwuY29tIDxm
bG93Y3J5cHQuY29tcGF0aWJpbGl0eUBwcm90b25tYWlsLmNvbT7CwHUEEAEI
ACkFAlskt/EGCwkHCAMCCRB+1D156WF2VQQVCAoCAxYCAQIZAQIbAwIeAQAA
2hYIANsYeRHhz5odpXWbeLc//Ex90llhgWb/kWWW5O5/mQwrOt+4Ct0ZL45J
GeXCQyirHiYhmA50BoDDfayqULDx17v6easDmfdZ2qkVxczc+TjF0VMI+Y/3
GrPuVddzBomc7qqYmEOkKEcnz4Q7mX5Ti1ImY8SSVPOchIbOQUFa96VhZJAq
Xyx+TIzalFQ0F8O1Xmcj2WuklBKAgR4LIX6RrESDcxrozYLZ+ggbFYtf2RBA
tEhsGyA3cJe0d/34jlhs9yxXpKsXGkfVd6atfHVoS7XlJyvZe8nZgUGtCaDf
h5kJ+ByNPQwhTIoK9zWIn1p6UXad34o4J2I1EM9LY4OuONvOwE0EWyS38AEI
ALh5KJNcXr0SSE3qZ7RokjsHl+Oi0YZBiHg0HBZsliIwMBLbR007aSSIAmLa
fJyZ0cD/BmQxHguluaTomfno3GYrjyM86ETz+C0YJJ441Fcji/0fFr8JexXf
eX4GEIVxQd4L0tB7VAAKMIGv/VAfLBpKjfY32LbgiVqVvgkxBtNNGXCaLXNa
3l6l3/xo6hd4/JFIlaVTEb8yI578NF5nZSYG5IlF96xX7kNKj2aKXvdppRDc
RG+nfmDsH9pN3bK4vmfnkI1FwUciKhbiwuDPjDtzBq6lQC4kP89DvLrdU7PH
n2PQxiJyxgjqBUB8eziKp63BMTCIUP5EUHfIV+cU0P0AEQEAAcLAXwQYAQgA
EwUCWyS38QkQftQ9eelhdlUCGwwAAKLKB/94R0jjyKfMGe6QY5hKnlMCNVdD
NqCl3qr67XXCnTuwnwR50Ideh+d2R4gHuu/+7nPo2juCkakZ6rSZA8bnWNiT
z6MOL1b54Jokoi1MreuyA7mOqlpjhTGbyJewFhUI8ybGlFWCudajobY2liF6
AdeK17uMFfR6I1Rid3Qftszqg4FNExTOPHFZIc8CiGgWCye8NKcVqeuVlXKw
257TmI5YAxZAyzhc7iX/Ngv6ZoR18JwKvLP1TfTJxFCG5APb5OSlQmwG747I
EexnUn1E1mOjFwiYOZavCLvJRtazGCreO0FkWtrrtoa+5F2fbKUIVNGg44fG
7aGdFze6mNyI/fMU
=D34s
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
  newerVersionOfExpired: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt Email Encryption 7.8.4
Comment: Seamlessly send and receive encrypted email

xsBNBF8PcdUBCADi8no6T4Bd9Ny5COpbheBuPWEyDOedT2EVeaPrfutB1D8i
CP6Rf1cUvs/qNUX/O7HQHFpgFuW2uOY4OU5cvcrwmNpOxT3pPt2cavxJMdJo
fwEvloY3OfY7MCqdAj5VUcFGMhubfV810V2n5pf2FFUNTirksT6muhviMymy
uWZLdh0F4WxrXEon7k3y2dZ3mI4xsG+Djttb6hj3gNr8/zNQQnTmVjB0mmpO
FcGUQLTTTYMngvVMkz8/sh38trqkVGuf/M81gkbr1egnfKfGz/4NT3qQLjin
nA8In2cSFS/MipIV14gTfHQAICFIMsWuW/xkaXUqygvAnyFa2nAQdgELABEB
AAHNKDxhdXRvLnJlZnJlc2guZXhwaXJlZC5rZXlAcmVjaXBpZW50LmNvbT7C
wI0EEAEIACAFAl8Pc5cGCwkHCAMCBBUICgIEFgIBAAIZAQIbAwIeAQAhCRC+
46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJ/awIAMVNZmNzQkWA9uZr
Rity+QME43ySC6p9cRx3o39apmOuVn6TOv/n9tfAlR/lYNZR80myhNi4xkQe
BpuTSJ8WAIw+9CIXrROV/YBdqvPXucYUZGjkAWzN6StQUfYP8nRm6+MebgLI
B/s+Lkr1d7wrDDF8rh7Ir9SkpXqr5FPTkDMsiFEbUR7oKpRoeI9zVtF375FB
ZJMUxm8YU+Tj1LAEullgrO9omHyMVqAVffZe6rH62c7L9ZR3C3/oG5rNcC/0
kIRsh0QGrq+kuZ6bsLFBhDLIjci8DH9yO1auceNy+Xa1U6scLb1ZZpVfV5R9
HWPy4QcNitDMoAtqVPYxPQYqRXXOwE0EXw9x1QEIALdJgAsQ0JnvLXwAKoOa
mmWlUQmracK89v1Yc4mFnImtHDHS3pGsbx3DbNGuiz5BhXCdoPDfgMxlGmJg
Shy9JAhrhWFXkvsjW/7aO4bM1wU486VPKXb7Av/dcrfHH0ASj4zj/TYAeubN
oxQtxHgyb13LVCW1kh4Oe6s0ac/hKtxogwEvNFY3x+4yfloHH0Ik9sbLGk0g
S03bPABDHMpYk346406f5TuP6UDzb9M90i2cFxbq26svyBzBZ0vYzfMRuNsm
6an0+B/wS6NLYBqsRyxwwCTdrhYS512yBzCHDYJJX0o3OJNe85/0TqEBO1pr
gkh3QMfw13/Oxq8PuMsyJpUAEQEAAcLAdgQYAQgACQUCXw9zlwIbDAAhCRC+
46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJzogH/2sRLw/hL2asprWR
U78VdhG+oUKKoNYvLFMJ93jhIB805E87kDB1Cietxg1xTj/lt911oK6eyoe4
CekCU25WkxmsAh0NUKz/1D6wJ1uDyh2lkmgyX+Iz9RCjtDHnnuzM1It77z6F
lGemOmYh8ZLYxJmG6e3MqHelRH25TuPm6fB0TN7lRlleTl26/8aJDBCvp7N1
4AdIgRWhBCoByCNe8QuNiZ0Bb+TLOt0jVVder645fVWx+4te0tpHTbGn9e3c
nLDskCEyJFvADug883x3lswUqh65zLO22m/plVmJ7X++whhSsDyQQRFiH0Du
1uh93GjDDNgrP1GfAMeRjZ4V8R8=
=R9m4
-----END PGP PUBLIC KEY BLOCK-----`,
  weakAlgo: `-----BEGIN PGP PUBLIC KEY BLOCK-----

xsBNBGANYRQBCADI3WP21Ut4L+g+qBBMk24cxsAX4N+FisqcxW7jhrqksH9Mi2vhpDFZyUCRe4d8
liXGTfiWnkp9qQIos8vnC6yPf9gNxsrjlccVVIiusoJB18KqsiKVBUiiqbNQwLUCACMA5PCALaBJ
1TRrTy5hWPCa8v+iyxTr2LaE7BcJCv1eGB3/vfsIt9zf2fsRga7FroJHSOdrxAPMu5rIU5iHwGPe
nFe2dSt8Y+dX5YKV7IBbjP7/Vp+/gV2HItaKmHFXP5FOtndPPCOtnIp6vUNZwA/o4K7tmiz6ZFp0
/Yn2DwUK0Nmmr+2v75FRnWqtelgACEDuGfrvYeJwAZIOmV0fr5yxABEBAAHNDXNoYTFAc2lnbi5j
b23CwIkEEwECADMWIQRXddqCmBkCxSCZ5qPIqyMsf2dexAUCYA1hGgIbAwULCQgHAgYVCAkKCwIF
FgIDAQAACgkQyKsjLH9nXsTM5AgAwWhDr2X9LY+7eJGyihkwXDCBZUvjF0hpY+8FYyxllfbW45pu
0bVs5T/EfnUYr+fOZuHdmhz4lNI2BPDwHhdQZpIqrrimD6jrypwcb500hwu5FKUBzw6U39QDuOSc
W6wIkiZ7hajTSTzniQRpbYZaKPrsFY40uZeQo6rAl71iuRsVvCjCazX8McOdGGP7oJCxtCpxaHoL
S2RcVu5/SWmEi8wHopDCKf/1UJphjJDeIHgdLwM6xMLrYBfbt6Fd2PYpJ17+ECs8Y9Q2v5nyXFaD
q+/Ri36rk3lz5YJGyB2AOFG+ma80SlOsCbA6j9Ky49tJZ1we6F368Lujrxnb+xMKY87ATQRgDWEa
AQgAqy0j+/GZvh4o7EabTtPKLOkVtQp/OV0ZGw6SKnhDB7pJhHKqgRduK4NYr1u+t575NI7EwgR3
7qoZkuvs/KmFizTxosCgL7WC6o5Groibc2XrL8mXbGDqWzKGllvKO+7gfkwx5qh0MoOXHWaavxE3
eXM6vvlATcjLkTjISiqzK/jSAmqB9J3GdqFafmtjqm/4Nfu1FGgpWi9JJxpv5aN8nILYksL/X+s8
ounYOz+OpUU+liv2wU3eRXP2/Qzc7Acdkrw5hRert9u+klHB3MckNUujVqq0mxB1yrPeJjqOBPCl
2n/wNLUoLqWbP/TW40MSFPAYdR/z+T67MDmRzVlewQARAQABwsB2BBgBAgAgFiEEV3XagpgZAsUg
meajyKsjLH9nXsQFAmANYR8CGwwACgkQyKsjLH9nXsSw8wf8CedMX61foCmCOEmKCscH+GcFKWwH
S4xlOPQZG4RXFla/VMvJrHqbxZ5vIID0GQ+t6kdhuD0ws9Y7DObFcSCxqPm8idkJUvC4kv1MSu+P
7NbWDS8t7e/b1EOu+aeIxqUhaQrJacWWiUn9tbobpld8GGlquLIteY9Ix2H/xjXnDvpB30v/fDNG
T/X6OnVQdcOI7SvdQI74SxbaHnEeCLDEk7dOhWLJBLuZwK7M3cT6BX+V2v6Fm7SX0hSpDg1HK0KL
qHJuDNEmMUvx3cMUd5HtsOFO9JapCp1iCVo2p49CIXA4NUrLETNM2ZddknhbFm8bsK48tTJEH6l4
Wq3aCVXYGg==
=Ldag
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
  dmitry: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYrr+kxYJKwYBBAHaRw8BAQdAl3dSHtMwIEq7pqZ68AZqUKsCElLBET6K
JwTh8v6bfXvNKkRtaXRyeSBhdCBGbG93Q3J5cHQgPGRtaXRyeUBmbG93Y3J5
cHQuY29tPsJ3BBAWCgAfBQJiuv6TBgsJBwgDAgQVCAoCAxYCAQIZAQIbAwIe
AQAKCRCVBUkqsjSkNv6dAP0RAf4+MmLIeFcB1dqwKgj/5cIZhdlt8BARvNLD
kgk1hgD+O4t3VtYG3aK7VOdc8RYEVzCIBWGA0xF7M2o7zp9C0wPOOARiuv6T
EgorBgEEAZdVAQUBAQdAiyNEwp+NGJNnDU/LBlHNh+lZbTIGlDd050EceDkL
13YDAQgHwmEEGBYIAAkFAmK6/pMCGwwACgkQlQVJKrI0pDbAGwD/eLXL8I+y
udeNtOHMPfrAvfOm1fPYWjRr58M64Osa1RAA/RySIH6WSBoyw79fQfI+uklB
xGiZ6dc7dKcqxEEVIJMM
=njJq
-----END PGP PUBLIC KEY BLOCK-----`
};
