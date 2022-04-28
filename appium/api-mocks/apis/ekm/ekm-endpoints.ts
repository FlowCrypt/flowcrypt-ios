/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

// import { HttpErr } from '../lib/api';
// import { isPut, isGet } from '../lib/mock-util';
// import { oauth } from '../lib/oauth';
// import { Dict } from '../../core/common';
// import { expect } from 'chai';
// import { KeyUtil } from '../../core/crypto/key';
// import { testConstants } from '../../tests/tooling/consts';
import { HandlersDefinition, HttpErr } from '../../lib/api';
import { EkmConfig, MockConfig } from '../../lib/configuration-types';
import { throwIfNotGetMethod } from "../../lib/mock-util";

// tslint:disable:max-line-length
/* eslint-disable max-len */
// tslint:disable:no-unused-expression
/* eslint-disable no-unused-expressions */

export class EkmHttpErr extends HttpErr {
  public formatted = (): unknown => {
    return { // follows EKM error response format
      "code": this.statusCode,
      "message": `message:${this.message}`,
      "details": `details:${this.message}`
    }
  }
}

export const MOCK_KM_LAST_INSERTED_KEY: { [acct: string]: { decryptedPrivateKey: string, publicKey: string } } = {}; // accessed from test runners

/**
 * Email Key Manager - distributes private keys to users who own them
 */
export const getMockEkmEndpoints = (
  mockConfig: MockConfig,
  ekmConfig: EkmConfig | undefined
): HandlersDefinition => {

  if (!ekmConfig) {
    return {};
  }

  // todo
  return {
    '/ekm/v1/keys/private': async ({ }, req) => {
      throwErrorIfConfigSaysSo(ekmConfig);

      throwIfNotGetMethod(req);

      const keys = ekmConfig.returnKeys ?? [];
      const decryptedPrivateKeys = keys.map((key) => ({ decryptedPrivateKey: key }));
      return {
        privateKeys: decryptedPrivateKeys
      };
    },
  };
}

const throwErrorIfConfigSaysSo = (config: EkmConfig) => {
  if (config.returnError) {
    throw new EkmHttpErr(config.returnError.message, config.returnError.code);
  }
}

// pub, primaryFingerprint, name, date are used to check Keys in KeyScreen and can be optional
export interface KeyDetailInfo {
  prv: string;
  pub?: string;
  primaryFingerprint?: string;
  name?: string;
  date?: string;
}

type KeyTypes = 'e2e' | 'flowcryptCompability' | 'key0' | 'key0Updated' | 'key1' | 'e2eRevokedKey' | 'e2eValidKey';

export const ekmPrivateKeySamples: Record<KeyTypes, KeyDetailInfo> = {
  e2e: {
    prv: '',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYUsiUhYJKwYBBAHaRw8BAQdAWssVJKjkDqTo78c6oRUWQzBU5EeM1jyt
sIYX7PzZh9bNOGUyZSBlbnRlcnByaXNlIHRlc3RzIDxlMmUuZW50ZXJwcmlz
ZS50ZXN0QGZsb3djcnlwdC5jb20+wngEExYKACAFAmFLIlICGwMFFgIDAQAE
CwkIBwUVCgkICwIeAQIZAQAKCRClTYK+FSHSDrWUAQDGmiilgW1Q97JzZ8eN
yevvnYl7FTNTGBiX+O9pFGaSdAEAukBYMV5fMXQihUdOQ8dL6Tfp7QQ4tuKo
I52QCvp1bQTOOARhSyJSEgorBgEEAZdVAQUBAQdApW7iwSvECJCJqHXevZCN
Pt3xHiaWNLd/gKeMyFuhYU0DAQgHwnUEGBYKAB0FAmFLIlICGwwFFgIDAQAE
CwkIBwUVCgkICwIeAQAKCRClTYK+FSHSDsUNAP9+YFUHDOCxJLmv6HZI6y2o
3HWm193CuAoB2mWLEg6cnAEAoiq3T6s5r5X880Yx+VdJSHposEtzbQtBrzl8
9//SbQE=
=n4ak
-----END PGP PUBLIC KEY BLOCK-----`,
    primaryFingerprint: '3810 0D21 F173 26E4 4786 9DA7 A54D 82BE 1521 D20E',
    name: 'e2e enterprise tests <e2e.enterprise.test@flowcrypt.com>',
    date: '9/22/21'
  },
  flowcryptCompability: {
    prv: '',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xsFNBFn7qV4BEACgKfufG6yseRP9jKXZ1zrM5sQtkGWiKLks1799m0KwIYuA
QyYvw6cIWbM2dcuBNOzYHsLqluqoXaCDbUpK8wI/xnH/9ZHDyomk0ASdyI0K
Ogn2DrXFySuRlglPmnMQF7vhpnXeflqp9bxQ9m4yiHMS+FQazMvf/zcrAKKg
hPxcYXC1BJfSub5tj1rY24ARpK91fWOQO6gAFUvpeSiNiKb7C4lmWuLg64UL
jLTLXO9P/2Vs2BBHOACs6u0pmDnFtDnFleGLC5jrL6VvQDp3ekEvcqcfC5MV
R0N6uVTesRc5hlBtwhbGg4HuI5cFLL+jkRwWcVSluJS9MMtug2eU7FAWIzOC
xWa+Lfb8cHpEg6cidGSxSe49vgKKrysv5PdVfOuXhL63i4TEnKFspOYB8qXy
5n3FkYF/5CpYN/HQaoCCxDIXLGp33u03OItadAtQU+qACaGmRhQA9qwe4i+k
LWL3oxoSwQ/aewb3fVo+K7ygGNltk6poHPcL0dU6VHYe8h2MCEO/1LR7yVsK
W47B4fgd3huXh868AX3YQn4Pd6mqft4WdcCuRpGJgvJNHq18JvIysDpgsLSq
QF44Z0GOH2vQrnOhJxIWNUKN+QnMy8RN6SZ1UFo4P+vf1z97YI2MfrMLfHB/
TUnsxS6fGrKhNVxN7ETH69p2rI6F836EZhebLQARAQABzTtGbG93Q3J5cHQg
Q29tcGF0aWJpbGl0eSA8Zmxvd2NyeXB0LmNvbXBhdGliaWxpdHlAZ21haWwu
Y29tPsLBfwQQAQgAKQUCWfupYwYLCQcIAwIJEK2sJ5yVCTIHBBUICgIDFgIB
AhkBAhsDAh4BAAoJEK2sJ5yVCTIHzuYP/2rnTuROyl4lyEM6rFX4dEaTkuSs
A2vGTQDs2wY0G348r4573o/aWMvuz6LfTQ3xrTBDKVo+blrj4Q9X79ir/7gT
+HLCan/FW7NR9YQ+LA9tUax3qzO8QhcyDdVx4ZHpkeyACzX3pKwvUxouCGGG
a2Ss/8itJQo0/ASK6I2FBOQjg2vJijwdgUpicKjcGcYa9Cipz8pKzgGX6QK5
xxHWNyROeEnuhQsSjFjrZygR3MB4kk7F/5wbSt9LArpfY9VoHdYxUSduOBEi
XezOnAZTayehk2Q4pa5qaPZ1TtLJU8A/2A+hgsjd694SdyBA58GStOaS/tba
zOu9fKclmssH0+tr1sy+6TapO7SIIV/h676x1TWLPxty5zfZuc5QiTJOcCj/
n/aJbM9y5bqWptmrpIP4dR1xJd5ZYvbvUJCZGxmhA1kfVApx/8aMm6UtJoI1
WLdAeozWLxwSy4bmo4UftbI1SCINJMH8WX0IBV8gC/C1ruJzWkhCAlJfIVQV
n/Vel5+FV+yZJFpRNyRAcmIrmZAA4UncpJSWJEfX0I1HOQHGbFIDrk17GOHx
tCBK8jM68UcNKoKhte64q9bqq7yw6wzNfBT1pFticBsxdGEecns7789x9616
IPq8hM3mQDePGcK87xkXLxGSRZgdQsEx61uFMpAufdqah0eSuJ1ewVE8zsFN
BFn7qV4BEACvxho8odwh4NMhmS+auCyX59sQAVdNEV4sMTcj3P+2M2IEmpwU
JsxY9wDCYXBXScfxIN4tKU6+qmwJ8M5GKEpvUfZOND0wPSz+ADAT+Ll4sG25
FdjZaP0TIJhzeCqrs8GP4WzSumboxbQxl6drP8KrX635nQ517lIZ4pazqOjU
fw67TGhJrF0wn0ImY55kpABCb1VCSooW/QudS8xUlj2BDJIzlqNN2UmCUejY
7m4zCtoVRG4fMEO1r73X7LDosDvoMF8O84m2aYQjAOwA1alHjNdKvo/kyxof
4L6ZtIIaoymbHZNnoZ3FJU0IQ5MGPCSeYiekE4YI2MGgHAtAJHuawP+5z5+m
DJ8ZT/0ezauudZfEgaM3E847HjksHmqx+bTHismrLU1hCBxQHea2CBKmsKcf
RfO5C8UYUI/TVEOrpJnUeuj/HpbJvQGXULmkBed6BEOc8LlCvPsF6g0wvOd1
7Xx7Ar8ShDT9GV178qlaNiDUTQTuVpUmEIxsaMaIbNV/gjAJhUg721e9HWVX
9HECfRonaHAL+9Azh3lwbjol2QashkjY3nD5dmxa+AOq+UTJzWQ62InlyThF
lKoGl9LjUGnF+AHnJioghMkdPFyhD1Z5yRlDO5jr4bhnR9GQtN2VD6iwIX1t
nMXLIjnk0O7XPCy2k7t+PD8VbD5DdfUWwQARAQABwsFpBBgBCAATBQJZ+6lk
CRCtrCeclQkyBwIbDAAKCRCtrCeclQkyB7m4D/40DjNX41ZE0imTJMM8PsUa
LimYVwxSz3pbNx53Hbjhq7iLEsumtI6Jvl4DVQiaNFam0kgjqtkkIdWsH+sU
lVCFIdolAKxJ3wrQ3UM46u/ihoasv3PLM90BNbyLNj2vMhFo2D1KLwO9Qt8o
iF4sjjb1FYN95gWMU9UnyfnmDBp/bw2m3GzKjiYRaF/6kX+XwdpC07MsHzY8
Tg1fCvN/YyiA3PdbkEy9xZmjVWZrgjPUgl8d02Vlgk7W8wLu7/slgDO3IfnS
ZdP0mHpTaOKbk4SUVE0RSHfkTUvYbpfNF04msRduCEXsQ76J6QjJFJx/akT6
80GEvaLCcmz4KGAUMUgadH5mPCXesbya7HSLKSx7m85OiJ3xIRnXqe7tYX1v
yEjE6szs0EAhpZUP2iqzDy76ffQynQMH6lzQyeHLTGMxZ1OYtyn5SvlHa5np
AJnSVjMsViztlbhfqZPdPC0ZZrt4E0hGLIAGbmDeOFOLyzBBeG/wy0bp4uLH
wfn9cM5lL3XLo+VR0CN8NLfj8h4yVLxIzVAiUGQseonXy+JA0erD2Jht/nns
0DoFWqjcDY5U/LIJVopGhgfctNxISnExyKo4eyq1iVKjt1HIk4RRDptYREgA
fm8L3l8EuB2q1535rkqr/uHHyx+th0vWUnK2IvRWAZZLQZUvVxkxTCG++7xv
Eg==
=r2et
-----END PGP PUBLIC KEY BLOCK-----`,
    primaryFingerprint: 'E8F0 517B A6D7 DAB6 081C 96E4 ADAC 279C 9509 3207',
    name: 'FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>',
    date: '11/2/17'
  },
  key0: {
    prv: `-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

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
qAcyYcY1rZf88Hcs0ubVCg==
=p0Yj
-----END PGP PRIVATE KEY BLOCK-----`,
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGJhte0BCAC+OTWjmuirrl0TKR7eAb77HU5eN/8s3+8lCe8xaAnlRtOXIMB3
BLEt0sBnvYnYMohdU3TqIbdLUCkgeK/4TKh3bkNyAL6p/p7Otv72/2jmI6s1XNC/
ClL2rr9xJKFfPPwb6EhnXZgcJOIH19xjM/OrlwJDyLtAKgoBMugEsLofJO91Iw72
Y7JtmJMLUpxnXp9RM40fTaq53LOlJF0SRdNvSRlalZeI8Vu1U7McT2EcSOvUDlrh
FwjZiVbloJNh63ELmCdmPdzswRBODOYDsrQ3i3gg9FQ4LGh7mYr7OBCi2xR2pHXb
hZJim+hQh8WGb497ymyaPcwgdB8+C4MEv1sdABEBAAG0GVRlc3QxIDx0ZXN0MUBl
eGFtcGxlLm5ldD6JAVQEEwEIAD4WIQTlg7RCGwswxMmb2A66kGcmgucQxwUCYmG1
7QIbAwUJB4YfbwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRC6kGcmgucQx+py
CAC8DleweXFH0lSS2Zzzq+MX83Jo7kIQ6YUsqejmJzr5rGZIVTJ9HtpJls6b+dSJ
Gq1hs3y1DA1DhbUM37eXE4C6NdC6Gkyp8RLtUTxi49l2AjF+isBax3YzmFRqEkfx
TRmEboeca2rksIpqLZ31gzPXfcUfUmm93nNqYBJzG9Y3bCg9Rh7flHh5KKcruUXZ
HK1utBIMIRB4VnGI7g8vDTASqdGeoUVvwv/UspSFhngUoHoITGA7NVNDQvWZxUJ5
2loGM5WwCU/Q2G140my09iHEjZZC7tGjehrV8Nua0UU5T4VK7TyfvlTr7pNcU8gl
e8fgxecOqbTYOxekfKcKpB1kuQENBGJhte0BCADisSqV9Fq5nfbrF0YlPbcLHGj5
n+1Sm3CkZzdERZITiigEYR19qsKeW6gzHu5NdN9odYR75pQ/2u8C8P3WveRKTplL
e+pi8PL2P2Q8aW7juTFgU/5ytMviiIZ6LikDi/c90STc+D4tyGYvud8mhTa04yGD
KeLgfZsy3Ql1B3L2xshPiMwKjtV7PJsDKyA0F39mCN/kIZoHaX1iIvPVPv47qFT7
HlO26KLFf3xZzS9kzb9Kz9e+fqmQz+iZgUyYKIkscqNfCsIo2f0EChas1+3jc0/Z
krQmlpwayBthino3+TD1z/6obyoMK27tKqRl+PD0tpZyKaiF9mw7gKfxCyi7ABEB
AAGJATwEGAEIACYWIQTlg7RCGwswxMmb2A66kGcmgucQxwUCYmG17QIbDAUJB4Yf
bwAKCRC6kGcmgucQxzlVB/4sVNwN+fKALKvxMpE+4uf2tTDlFNLEouaJEilM6TKX
Oj5fc3ld60Sivw8StgG8Cszw+80ektjIypV8nU6aeNnhRhDyKSugb2CGL0o9UnnG
WHIjVczg6cqTr5203q1criTjfkSyp9F2pP3ixvC+KRyxT5ge0UfadB6Uldg9c2yD
koesQ3aTakf0GDxEC3X6GlElB2ZLQmOOyFVIoqjwk5GhPhYYzzAdgK5Cupf1NiGG
9DO9vSsIHsxFGvrFETXPfP1bb95ifMFocx0vdWF08A9C0FnrcCh4IfCcwBF71i/r
l2IyabtIoeuUOpEqo9k0BEuoBzJhxjWtl/zwdyzS5tUK
=X7jE
-----END PGP PUBLIC KEY BLOCK-----`,
    primaryFingerprint: 'E583 B442 1B0B 30C4 C99B D80E BA90 6726 82E7 10C7',
    name: 'Test1 <test1@example.net>',
    date: '4/21/22',
  },
  key0Updated: {
    prv: `-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

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
BzJhxjWtl/zwdyzS5tUK
=eZlX
-----END PGP PRIVATE KEY BLOCK-----`,
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=8Vls
-----END PGP PUBLIC KEY BLOCK-----`,
    primaryFingerprint: 'E583 B442 1B0B 30C4 C99B D80E BA90 6726 82E7 10C7',
    name: 'test1-new <test1-new@example.net> Test1 <test1@example.net>',
    date: '4/21/22',
  },
  key1: {
    prv: `-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

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
R9d4w5Nckrf25GKSPH0b4A==
=s5ap
-----END PGP PRIVATE KEY BLOCK-----`,
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGJhtxwBCACeaKsz+7j1FlPUOM0Yri0JsvK+OU4C1tfr7uDvYrWwuYLluXrm
FCdKie0EyHjLfqP+7QSsnjtRW9LZuTk3zBCHv8By38w/BDr2bWhQ6WWEkLxdm3NI
4k6+NcQjfsg0TKgbv28pW7N3fKeU05/opMVetjviYeNZAYHHcV2uh53TYVowGDpV
cJxBEimYLHL84Gsf14LSShsI8+ZDlM4q7tbR7sOCmSDOlGIj9rnO28sr4Gp78pTf
WoC/zfYuGC6XYj3HYRkKrprE+PMOofugy9Qd1GZtqsMt1rlEj/0dwrrltHw3zKXE
ATAEorPZRSjxpozDy3oXePore9h1+C+ORej5ABEBAAG0GVRlc3QyIDx0ZXN0MkBl
eGFtcGxlLm5ldD6JAVQEEwEIAD4WIQQlOgS63Ov+RuCievvnktGEMS6ymQUCYmG3
HAIbAwUJB4YfcAULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRDnktGEMS6ymYoX
CACNf3RNyXdIUnsUVAcTx2jFXTB8baFm2X941hieOxKnCx78P5Rjbi/pgzOKrIgD
bRn0eXtH8QDQExyo47ScpxpDMc3iKJRQJU7nTCIClwMeWUYR9Sh7BRUXXqMcHKA7
vasgu6fK3k8Cj/jOlTMZIYkOKSxhaDtvIhvugxURMHJZ0Ul0hewiHBCgqtO+f+9S
LOFPBj6mvq9qQ2WmBa8kImoCusrL8B1/wf7kciKzAfQNpQ+FteJ8zS4eA3TydwvS
OnE/U/8rCBPE6hDHT+9zPugeDgOS4PF6PHsX49K9IabSOfvbpDm+hqbDHnwxqkRm
huIwNPLeeTDp7IWVj7PIquFVuQENBGJhtxwBCADRrSWddGQFVssWs9N9rBZ7WPO7
wrwjHA2lAFysDdnea3cXfRQvw0TUmLvKzzk0frcZXsDi8Uc7vkWiBrVFUHsUJI5F
JYRqvk/2lhdVb9JQxWi6jafOBWq2SYA6r2hQv6y/c/woIulQTg/PsAs3bBPM3HU5
cLWvWDCVikKgDcHaT9nXR5egI41eIuxqwJqZFYCAo0UAZdT9SmqeLV4ZbiC8za4D
lR5zHW0MvIAfP9LJkjThH0KdlZE51BD6xK94HYxNAaojgBpCtpVWnZUn5Owvwjor
pTw++eAX3uK9mQX+Pot9yytQa4vh/zSRUrwqiZ6pM1G8/db20Wqg/ZHwmIXrABEB
AAGJATwEGAEIACYWIQQlOgS63Ov+RuCievvnktGEMS6ymQUCYmG3HAIbDAUJB4Yf
cAAKCRDnktGEMS6ymdXMB/0eP6XG/5r+ryy1L9maORZQNwYneI9lxnEqYMKBSi7b
hQCwudGzcUwNUoCqkoptT24Zm3od133Zjl5te5iRKKpaESt9Xx4m1BLgxGoW1s7f
cjT58Hz53t/AjiBwVc0WGEGESkQI/RaftXXz2LbbQYwDqEdRfta/R0wqs60Otnmy
Xv00dJYlZNadimW3VzVoDTp25ZH1lw/bTlQrklYjdSzBo0fcyXBMF435EJlsJRcX
2gxnyhsvJB/v3yO/8Mo8zufXT/WON9Qb6fIWFJJ3Bh7Yf3Gm8i6QQzT3Df67/uKo
xa0hb0caoaEpLJCj45Us7oBH13jDk1ySt/bkYpI8fRvg
=EY/L
-----END PGP PUBLIC KEY BLOCK-----`,
    primaryFingerprint: '253A 04BA DCEB FE46 E0A2 7AFB E792 D184 312E B299',
    name: 'Test2 <test2@example.net>',
    date: '4/21/22',
  },
  e2eRevokedKey: {
    prv: `
    -----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email
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
pojfAZbWHcKn2vZgEtUYdkAwFQ6wEZs=
=zPzB
-----END PGP PRIVATE KEY BLOCK-----
    `
  },
  e2eValidKey: {
    prv: `
    -----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email
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
Uw==
=C1hl
-----END PGP PRIVATE KEY BLOCK-----`
  }
};
