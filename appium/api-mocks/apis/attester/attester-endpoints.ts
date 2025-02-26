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

xsBNBGe8f5YBCADKlxrQrX1lD9A9r6eZJTSYAf5GS7/dUTEUvatcbkxQA3op
ZiRD3u5pCW4g/xwIKy4RHZwjcx3DSDe1sbrlc1J43GJx5PxeNhMVmJyayX6N
UXildWPDLalrfdkE1TVHrGMuiiMjNtXvj2KaLMwkn0YYuy0ja+pbO6IRXbs8
dZy1K4MtLDLhShsdnJKW4eTpfNMQCwCV6/wGnmtWiNiazN2AVOCZkpSTMlRU
pr1AlhqEYU5+v9W0l776f/rlr9CJS/zLO2tEXPBQ0TwpBDeMAXvYawbjDQLl
ianD8wbOnjJaXwkCgLk+eswqMcnzV07hMsw9416k9NUj1mzT6Krx2yiFABEB
AAHNIlRvbSBKYW1lcyBIb2x1YiA8dG9tQGJpdG9hc2lzLm5ldD7CwNEEEwEK
AIUFgme8f5YDCwkHCZBaO6QCM1etOkUUAAAAAAAcACBzYWx0QG5vdGF0aW9u
cy5vcGVucGdwanMub3Jn5NW4xPKTYgR7DXb0YM8eu9UY0paT7zR+xmj3sZlN
nM8FFQoIDgwEFgACAQIZAQKbAwIeARYhBP85sL6E8thcQJE6flo7pAIzV606
AAAfPQf+Ld1PY4M5Kci79Q/8ca5UWND356hgaAxDpbY3SjsGLyNL3uGEpgCd
160PEC6wSb4XTT/sbYmri9MZFxtQL27VZ9NDvC7BRrFyVDI4gLyV/Cn+X0vQ
pgo0/FjVdtFp6Nhrebd+S53DqhG+SQUGFUG+V9u5inuFmuk1mLXZPMhMawSo
ceQ3g91InFaW5f3TtgaJWMYUdcOq1oNlcihZ+4nwQ5aNl5h+0+uUH91EhwDi
Ef1aZiKOZXpLojwNjsYi8CNxGgm21WsrH3i1D+SO14LreZ/n0XM3KhgTqCXh
7xzvMlaJ0GKUP02qJ+a/WQGJt6M0WqNhGKri7JEjerivTxas0c7ATQRnvH+W
AQgArHU8cHVTrjNHwi4FaxIA2/bUDXo6crJDCndSmCpb1xWwD6QHfZCNhnoq
EhzAdnpuBbeRSy4gLjy2p3WParY2qxPGD1y5IqqrtU4XoEHne52wEYhYRtAl
MDn9dpcSwD56QcDFb6f4iRcy3nUytMoto3Drj5ZV9w3Zbn6vRdcZbQBMs9UN
iRbBGZmqCkiDy8G4iypUppj8EIpYKtDcksKopAqAFaoaiaYcJfsaGUrY79Qm
hW3bTDv1KXV/rDISmhLzvTfcAVvzmXhQW+72R8Jq66J5C6QjJlmpCEDrlq7c
N3CVLxt2EDdBt3J2cDKUepYaoxjWHZ5bu1w5OOzNsYAGBQARAQABwsC8BBgB
CgBwBYJnvH+WCZBaO6QCM1etOkUUAAAAAAAcACBzYWx0QG5vdGF0aW9ucy5v
cGVucGdwanMub3JnocFsW7hmuFFWoAWIuLCc+fvYCCE335PuEBpp044fHCsC
mwwWIQT/ObC+hPLYXECROn5aO6QCM1etOgAA+p0H/ie/DOMLkDAnpAYVN+kc
Hl2CsyW1eb0lub0Gr8mcguoyF32Me6R567L28d/rWQyyoB9Z/U5qt47iJEPv
qmfWRM5bX17C/lEOCPu9EpXYDFTrl7+ElDTjSi8rxF9F+xIb91KS7pjBi9ot
2uuz9estluGZMDrcf3CD3H1arm/AEzfqcVAglqKoQ4acnexYRxoz/3p94g6w
YYTibj9NVZ2+GULB6kM+yj28PIXjXhHwH3fDoozGIXFWsY8EQ9GRrRlIOYt0
QiDWeY8UfTXlwnErVPf0W75qI5Ld4zKwQ46LGwSgFs0Mdzhop+9twH3P6JbR
eJZacaTiwQdOZTyd4p+hCFE=
=H77I
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
