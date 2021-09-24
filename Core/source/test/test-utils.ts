/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import * as ava from 'ava';
import * as https from 'https';
import * as fs from 'fs';
import { config, expect } from 'chai';
import { Subprocess } from './subprocess'
import { readFileSync } from 'fs';
import { Buf } from '../core/buf';
config.truncateThreshold = 0

export type AvaContext = ava.ExecutionContext<any>;
type JsonDict = { [k: string]: any };
type TestKey = { pubKey: string, private: string, decrypted: string, passphrase: string, longid: string };

const stderrs: string[] = [];
const stdouts: string[] = [];

export const startNodeCoreInstance = async (t: AvaContext) => {
  const r = await Subprocess.spawn('node', ['build/final/flowcrypt-android-dev.js'], `listening on 3000`);
  await wait(500); // wait for initial rn-bridge msg to pass
  const stdLog = (type: 'stderr' | 'stdout', content: Buffer) => {
    const msg = `node ${type}: ${content.toString().trim()}`;
    if (type === 'stderr') {
      stderrs.push(msg);
      console.error(msg);
    } else {
      stdouts.push(msg);
      console.log(msg);
    }
  };
  Subprocess.onStderr = ({ stderr }) => stdLog('stderr', stderr);
  Subprocess.onStdout = ({ stdout }) => stdLog('stdout', stdout);
  return r;
};

const getSslInfo = new Function(`${readFileSync('source/assets/flowcrypt-android-dev-begin.js').toString()}\nreturn {NODE_SSL_CA,NODE_SSL_CRT,NODE_SSL_KEY,NODE_AUTH_HEADER};`);
const { NODE_SSL_CA, NODE_SSL_CRT, NODE_SSL_KEY, NODE_AUTH_HEADER } = getSslInfo();
const requestOpts = { hostname: 'localhost', port: 3000, method: 'POST', ca: NODE_SSL_CA, cert: NODE_SSL_CRT, key: NODE_SSL_KEY, headers: { Authorization: NODE_AUTH_HEADER } };

export const request = (endpoint: string, json: JsonDict, data: Buffer | string | (never | undefined)[], expectSuccess = true): Promise<{ json: JsonDict, data: Buffer, err?: string, status: number }> => new Promise((resolve, reject) => {
  const req = https.request(requestOpts, r => {
    const buffers: Buffer[] = [];
    r.on('data', buffer => buffers.push(buffer));
    r.on('end', () => {
      const everything = Buffer.concat(buffers);
      const newlineIndex = everything.indexOf('\n');
      if (newlineIndex === -1) {
        console.log('everything', everything);
        console.log('everything', everything.toString());
        reject(`could not find newline in response data`);
      } else {
        const jsonLine = everything.slice(0, newlineIndex).toString();
        const json = JSON.parse(jsonLine);
        const data = everything.slice(newlineIndex + 1);
        const err = json.error ? json.error.message : undefined;
        const status = r.statusCode || -1;
        if (expectSuccess && (status !== 200 || typeof err !== 'undefined')) {
          reject(`Status unexpectedly ${status} with err: ${err}`);
        } else {
          resolve({ json, data, err, status });
        }
      }
    });
  });
  req.on('error', reject);
  req.write(endpoint)
  req.write('\n');
  req.write(JSON.stringify(json));
  req.write('\n');
  req.write(data instanceof Buffer ? data : Buffer.from(data as string));
  req.end();
});

export const httpGet = async (url: string): Promise<Buf> => {
  return await new Promise((resolve, reject) => {
    const req = https.request(url, r => {
      const buffers: Buffer[] = [];
      r.on('data', buffer => buffers.push(buffer));
      r.on('end', () => {
        const buf = Buf.fromUint8(Buffer.concat(buffers));
        const status = r.statusCode || -1;
        if (status !== 200) {
          reject(`Status unexpectedly ${status} for url ${url}`);
        } else {
          resolve(buf);
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

export const expectEmptyJson = (json: JsonDict) => {
  expect(Object.keys(json)).to.have.property('length').that.equals(0);
}

export const expectNoData = (data: Buffer) => {
  expect(data).to.be.instanceof(Buffer);
  expect(data).to.have.property('length').that.equals(0);
}

export const expectData = (data: Buffer, type?: 'armoredMsg' | 'msgBlocks' | 'binary', details?: any[] | Buffer) => {
  expect(data).to.be.instanceof(Buffer);
  expect(data).to.have.property('length').that.does.not.equal(0);
  const dataStr = data.toString();
  if (type === 'armoredMsg') {
    expect(dataStr).to.contain('-----BEGIN PGP MESSAGE-----');
    expect(dataStr).to.contain('-----END PGP MESSAGE-----');
  } else if (type === 'msgBlocks') {
    const blocks = data.toString().split('\n').map(block => JSON.parse(block));
    expect(details).to.be.instanceOf(Array);
    const expectedBlocks = details as any[];
    expect(blocks).to.have.property('length').which.is.greaterThan(0);
    expect(blocks[0]).to.have.property('type').which.equals('plainHtml'); // todo plainHtml - should be renambed - legacy compat reasons
    const renderedContentBlocksBlock = blocks.shift();
    const [head, body, foot] = renderedContentBlocksBlock.content.split(/<\/?body>/g);
    expect(head).to.contain('<!DOCTYPE html><html>');
    expect(head).to.contain('<style>');
    expect(head).to.contain('<meta name="viewport" content="width=device-width" />');
    expect(foot).to.contain('</html>');
    if (body.includes('<!-- next MsgBlock -->\n')) {
      const renderedContentBlocks = body.split('<!-- next MsgBlock -->\n');
      const lastEmpty = renderedContentBlocks.pop(); // last one should be empty due to the splitting above
      expect(lastEmpty).to.equal('');
      for (const renderedContentBlock of renderedContentBlocks) {
        const m = (renderedContentBlock as string).match(/<div class="MsgBlock ([a-z]+)" style="[^"]+">(.*)<\/div>/);
        if (m === null) {
          blocks.unshift({ error: "TEST VALIDATION ERROR - MISMATCHING CONTENT BLOCK FORMAT", content: renderedContentBlock });
        } else {
          blocks.unshift({ rendered: true, frameColor: m[1], htmlContent: m[2] });
        }
      }
    }
    expect(blocks.length).to.equal(expectedBlocks.length);
    for (let i = 0; i < expectedBlocks.length; i++) {
      // if (i === 0 && blocks[i].type === 'decryptedHtml') {
      // }
      expect(blocks[i]).to.deep.equal(expectedBlocks[i], `block ${i} failed cmp check`);
    }
  } else if (type === "binary") {
    expect(details).to.be.instanceOf(Buffer);
    const expectedBuffer = details as Buffer;
    expect(data).to.deep.equal(expectedBuffer);
  } else if(typeof details !== 'undefined') {
    throw Error("Unknown test type");
  }
}

const TEST_KEYS: { [name: string]: TestKey } = {
  'rsa1': {
    pubKey: '-----BEGIN PGP PUBLIC KEY BLOCK-----\nVersion: FlowCrypt 6.3.5 Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwHUEEAEIACkFAlwBWOEGCwkHCAMCCRA6\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAA1pMH/R9oEVHaTdEzs/jbsfJk\n6xm2oQ/G7KewtSqawAC6nou0+GKvgICxvkNK+BivMLylut+MJqh2gHuExdzx\nHFNtKH69BzlK7hDBjyyrLuHIxc4YZaxHGe5ny3wF4QkEgfI+C5chH7Bi+jV6\n94L40zEeFO2OhIif8Ti9bRb2Pk6UV5MrsdM0K6J0gTQeTaRecQSg07vO3E8/\nGwfP2Dnq4yHICF/eaop+9QWj8UstEE6nEs7SSTrjIAxwAeZzpkjkXPXTLjz6\nEcS/9EU7B+5v1qwXk1YeW1qerKJn6Qd6hqJ5gkVzq3sy3eODyrEwpNQoAR4J\n8e3VQkKOn9oiAlFTglFeBhfOwE0EXAFY4QEH/2dyWbH3y9+hKk9RxwFzO+5n\nGaqT6Njoh368GEEWgSG11NKlrD8k2y1/R1Nc3xEIWMHSUe1rnWWVONKhupwX\nABTnj8coM5beoxVu9p1oYgum4IwLF0yAtaWll1hjsECm/U33Ok36JDa0iu+d\nRDfXbEo5cX9bzc1QnWdM5tBg2mxRkssbY3eTPXUe4FLcT0WAQ5hjLW0tPneG\nzlu2q9DkmngjDlwGgGhMCa/508wMpgGugE/C4V41EiiTAtOtVzGtdqPGVdoZ\neaYZLc9nTQderaDu8oipaWIwsshYWX4uVVvo7xsx5c5PWXRdI70aUs5IwMRz\nuljbq+SYCNta/uJRYc0AEQEAAcLAXwQYAQgAEwUCXAFY4QkQOjD0zAqajxAC\nGwwAAI03B/9aWF8l1v66Qaw4O8P3VyQn0/PkVWJYVt5KjMW4nexAfM4BlUw6\n97rP5IvfYXNh47Cm8VKqxgcXodzJrouzgwiPFxXmJe5Ug24FOpmeSeIl83Uf\nCzaiIm+B6K5cf2NuHTrr4pElDaQ7RQGH2m2cMcimv4oWU9a0tRjt1e7XQAfQ\nSWoCalUbLBeYORgVAF97MUNqeth6FMT5STjq+AGgnNZ2vdsUnASS/HbQQUUO\naVGVjo29lB6fS+UHT2gV/E/WQInjok5UrUMaFHwpO0VNP057DNyqhZwxaAs5\nBsSgJlOC5hrT+PKlfr9ic75fqnJqmLircB+hVnfhGR9OzH3RCIky\n=VKq5\n-----END PGP PUBLIC KEY BLOCK-----\n',
    private: '-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\nxcMGBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\nAAH+CQMIOXj58ei52QtgxArMeSOTfW3TXaT8V9bVH6G0wK1mVtHIZl5OXVkd\nDWiOdwHiCPmphMkIeWurg5j8aL0vPTJx2pGFrfr/+Nj4LKfL3LC3UrEsYVQg\nFyT5pSFYCONnMb3+uBg6mdBaCG9U7WyzSvAMH0bWhX4X1rEdReJO5CVwl84A\nUN00olSMKW2KZ7BtwADm0qf/vfmfMH6BYrdZVhK1KXsXWLvvVhu7Y60a/V3c\nU7okca2Fe8OzJpk3yJDkiT7IhDqePE5UCRBV6CYFAJeAbA/R38mysVGFGM9J\nCRHmhiqsRt/USkQ2Il+Cc4BpiS7wMv8uhIWACg66jN7EsqmHXcdKkq3N6DgB\nABQzxfEXdUaqJbNEbkJamhgSWfwmL3Va59vADp4BgaogMCaPT0p4GS7vwtt3\nvIOUB0CKgPTofyh1G5pW6DGLX5UthxLs6+Nt4woaD90zTYwld1cG6HjmYBmy\nwVEpxkFSnYtHimEP+nq1pll/3I2wKwVbZFELXaRNTWiYVkjhLR9Vbx1E7Mkg\ngjc72zxAxYso7oCtAODhjy5WA0vKV830500cHUaiDtHmCSOqnJHJ5kcIWtC2\ny1qt25jv8wOHCpLT77z1OkIS/keabRwvaivWH7TXp3qKvyCYyhO4EpoJk29n\nLACVZBVZFmLy6/oyVWrRXXFWeURtb/dUZG1k9AZlecMrTIaEAJKqDBshjat/\neF0KhJ+C2AdIe2PCnX4LWS4Y6shM4VZoRcSBzpx8QbhOUUzAM5WYm9JH7kTE\nF9p0qqKVHbXHFup7p2ptjwyL3Axu3Oi8/8pqRe2Kl+YVfR0JWT7/UZTDQomq\ns72AFZddJy6RbgfeJxX376UhUqDVgZN07Ih2PcCcex8Bf10IccMNC74dxmAy\nYtf6LQP7Uws0pyqiusBZJoNsdgsJ9MbTzRBUZXN0IDx0QGVzdC5jb20+wsB1\nBBABCAApBQJcAVjhBgsJBwgDAgkQOjD0zAqajxAEFQgKAgMWAgECGQECGwMC\nHgEAANaTB/0faBFR2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CA\nsb5DSvgYrzC8pbrfjCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWs\nRxnuZ8t8BeEJBIHyPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeT\nK7HTNCuidIE0Hk2kXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBO\npxLO0kk64yAMcAHmc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kH\neoaieYJFc6t7Mt3jg8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXx8MGBFwB\nWOEBB/9nclmx98vfoSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNst\nf0dTXN8RCFjB0lHta51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdM\ngLWlpZdYY7BApv1N9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLL\nG2N3kz11HuBS3E9FgEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYB\nroBPwuFeNRIokwLTrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+\nLlVb6O8bMeXOT1l0XSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAH+CQMI\nPqtEWmogeSBgMbGVnYVID1zzpRIum4ifUnA7HOgJ/AbrWrD6OvUjQsHsQtSo\njANPVtL85PICEKGDLm/wFKzENgB1ZsFvSi6IwdOIdq4rckCgJRw+R0xNxtiX\nFoqoFM5MkwQRfrXJgWO0YjdG2AGMsPufWRV9N2aFBoiWQqbxvkmOdO4/qAdS\nFOGr1+eu3P693yuuZlD9cdO44Md28PtldoXenNhLuEqxhw8/Yb1/U8u66WAl\nz9JUYLwI4U/juhqekU+zNWs9H0Bh1yd4dcN9NT0nyc1GrdCKypcWth2DVMmP\nzFluwz4NnIW2VokE5rKofKUXbEYstua0ZY5Vz9mdNEmX9LZmBwCLwwC0j71d\nKYiJWVgxL28jCrF85eBqnmXEIkoE6hGeptaBZ8nTkSMpEdZZCif6+Vxn9JAd\nG9KYV/EeP2Hf07aYI6YRMmgNSHIso5m5rrfX9E8P2mhmqAhiV6xBPDJM4SdQ\n1y93zUm/rpWflBw3PkC6CHtZ2pem9aLdigBcIgGYtmbblY234vT/EdlA8OPy\nqUXZ8HPIby911qzDmWEXdhuG8OdIhvp4GVgyJ6sUvgzrcDM4Uond7jG8m5O3\nlQmbYBx3L4ZLYoUW5pIjxXVWSPrbBhjnShwwNukhj2GfXOS8+gZS0Mrw/EVT\nBUIe4sgiv0M7XaVXX+CYMJ+1dsWzgPwMqN3MrxCgf2D7ujsfSTHunE5sCei1\nO0H2SAL3Lr2V2b2PnfRy/UMPaFdAfxXGJKrOdpuM27LZvAa+QeLKA0emlZuT\n4nKsl1QGzTV/3EI2gdCYLyjwOq05qdCy0B/0tfJ2tXS1AOPPaKcDyCkrenzA\nw6rZipO7t7oQYsDXOzZEE1Y370M8DFBTcVbC5OjRy1M/REXD5QIP9Fl4DYUW\ngk8zqqjQfuyQkd0r3kS0NHL1wsBfBBgBCAATBQJcAVjhCRA6MPTMCpqPEAIb\nDAAAjTcH/1pYXyXW/rpBrDg7w/dXJCfT8+RVYlhW3kqMxbid7EB8zgGVTDr3\nus/ki99hc2HjsKbxUqrGBxeh3Mmui7ODCI8XFeYl7lSDbgU6mZ5J4iXzdR8L\nNqIib4Horlx/Y24dOuvikSUNpDtFAYfabZwxyKa/ihZT1rS1GO3V7tdAB9BJ\nagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJOOr4AaCc1na92xScBJL8dtBBRQ5p\nUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlStQxoUfCk7RU0/TnsM3KqFnDFoCzkG\nxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtwH6FWd+EZH07MfdEIiTI=\n=15Xc\n-----END PGP PRIVATE KEY BLOCK-----',
    decrypted: '-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: FlowCrypt 0.0.1-dev Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\n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\nd+EZH07MfdEIiTI=\n=GVVZ\n-----END PGP PRIVATE KEY BLOCK-----\n',
    passphrase: 'some long pp',
    longid: '3A30F4CC0A9A8F10'
  },
  'rsa2': {
    pubKey: '-----BEGIN PGP PUBLIC KEY BLOCK-----\nVersion: FlowCrypt 6.3.5 Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\n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\nKQk670ezsXQMRX/AeM4Ttn2ZIjItmIpo7mUOfqE=\n=eep/\n-----END PGP PUBLIC KEY BLOCK-----\n',
    private: '-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: FlowCrypt  Email Encryption - flowcrypt.com\nComment: Seamlessly send, receive and search encrypted email\n\n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\nDn6h\n=5aR+\n-----END PGP PRIVATE KEY BLOCK-----',
    decrypted: '', // todo in case needed
    passphrase: 'some long pp',
    longid: '7C307E6F2092962D'
  },
  'ecc': {
    pubKey: '-----BEGIN PGP PUBLIC KEY BLOCK-----\nVersion: FlowCrypt 6.3.5 Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\nxjMEXAZt6RYJKwYBBAHaRw8BAQdAHk2PLEMfkVLjxI6Vdg+dnJ5ElKcAX78x\nP+GVCYDZyfLNEXVzciA8dXNyQHVzci5jb20+wncEEBYKACkFAlwGbekGCwkH\nCAMCCRAGNjWz4z6xTAQVCAoCAxYCAQIZAQIbAwIeAQAA5H0A/3J+MZijs58O\no18O5vY33swAREm78aQLAUi9JWMkxdYOAQD2Cl58wQDDoyx2fgmS9NQOSON+\nTCaGfIaPldt923KqD844BFwGbekSCisGAQQBl1UBBQEBB0BqkLKrGBakm/MV\nNicvptKH4c7UdikdbpHPlfg2srb/dQMBCAfCYQQYFggAEwUCXAZt6QkQBjY1\ns+M+sUwCGwwAAJQrAP4xAV2NYRnB8CcllBYvHeOkXE3K4qNQRHmFF+mEhcZ6\npQD/TCpMKlsFZCVzCaXyOohESrVD+UM7f/1A9QsqKh7Zmgw=\n=WZgv\n-----END PGP PUBLIC KEY BLOCK-----\n',
    private: '-----BEGIN PGP PRIVATE KEY BLOCK-----\nVersion: FlowCrypt 6.3.5 Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\nxYYEXAZt6RYJKwYBBAHaRw8BAQdAHk2PLEMfkVLjxI6Vdg+dnJ5ElKcAX78x\nP+GVCYDZyfL+CQMI1riV1EDicFNg4/f/0U/ZJZ9udC0F7GvtFKagL3EIqz6f\nm+bm2E5qdDdyM2Z/7U2YOOVPc/HBxTg9SHrCTAYmfLtXEwU21uRzKIW9Y6N0\nLs0RdXNyIDx1c3JAdXNyLmNvbT7CdwQQFgoAKQUCXAZt6QYLCQcIAwIJEAY2\nNbPjPrFMBBUICgIDFgIBAhkBAhsDAh4BAADkfQD/cn4xmKOznw6jXw7m9jfe\nzABESbvxpAsBSL0lYyTF1g4BAPYKXnzBAMOjLHZ+CZL01A5I435MJoZ8ho+V\n233bcqoPx4sEXAZt6RIKKwYBBAGXVQEFAQEHQGqQsqsYFqSb8xU2Jy+m0ofh\nztR2KR1ukc+V+Daytv91AwEIB/4JAwhPqxwBR+9JFWD07K5gQ/ahdz6fd7jf\npiGAGZfJc3qN/W9MTqZcsl0qIiM4IaMeAuqlqm5xVHSHA3r7SnyfGtzDURM+\nc9pzQRYLwp33TgHXwmEEGBYIABMFAlwGbekJEAY2NbPjPrFMAhsMAACUKwD+\nMQFdjWEZwfAnJZQWLx3jpFxNyuKjUER5hRfphIXGeqUA/0wqTCpbBWQlcwml\n8jqIREq1Q/lDO3/9QPULKioe2ZoM\n=8qZ6\n-----END PGP PRIVATE KEY BLOCK-----',
    decrypted: '', // todo in case needed
    passphrase: 'some long pp',
    longid: '063635B3E33EB14C',
  },
  'gpg-dummy': { // first key is a dummy primary key, with an actual subkey. Achieved with gnupg --export-secret-subkeys
    pubKey: '-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n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\nfga3xzGyrbBy00LYVylMDvs5GPYyCCi7Ch9cgvg=\n=nkDv\n-----END PGP PUBLIC KEY BLOCK-----',
    private: '-----BEGIN PGP PRIVATE KEY BLOCK-----\n\n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\n=R73C\n-----END PGP PRIVATE KEY BLOCK-----',
    decrypted: '', // todo in case needed
    passphrase: 'FlowCrypt',
    longid: '96FB3C9661A5573C',
  },
  'expired': {
    pubKey: '-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt Email Encryption 7.8.4\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBF8PcdUBCADi8no6T4Bd9Ny5COpbheBuPWEyDOedT2EVeaPrfutB1D8i\r\nCP6Rf1cUvs/qNUX/O7HQHFpgFuW2uOY4OU5cvcrwmNpOxT3pPt2cavxJMdJo\r\nfwEvloY3OfY7MCqdAj5VUcFGMhubfV810V2n5pf2FFUNTirksT6muhviMymy\r\nuWZLdh0F4WxrXEon7k3y2dZ3mI4xsG+Djttb6hj3gNr8/zNQQnTmVjB0mmpO\r\nFcGUQLTTTYMngvVMkz8/sh38trqkVGuf/M81gkbr1egnfKfGz/4NT3qQLjin\r\nnA8In2cSFS/MipIV14gTfHQAICFIMsWuW/xkaXUqygvAnyFa2nAQdgELABEB\r\nAAHNKDxhdXRvLnJlZnJlc2guZXhwaXJlZC5rZXlAcmVjaXBpZW50LmNvbT7C\r\nwJMEEAEIACYFAl8PcdUFCQAAAAEGCwkHCAMCBBUICgIEFgIBAAIZAQIbAwIe\r\nAQAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJIvQIALG8TGMN\r\nYB4CRouMJawNCLui6Fx4Ba1ipPTaqlJPybLoe6z/WVZwAA9CmbjkCIk683pp\r\nmGQ3GXv7f8Sdk7DqhEhfZ7JtAK/Uw2VZqqIryNrrB0WV3EUHsENCOlq0YJod\r\nLqtkqgl83lCNDIkeoQwq4IyrgC8wsPgF7YMpxxQLONJvChZxSdCDjnfX3kvO\r\nZsLYFiKnNlX6wyrKAQxWnxxYhglMf0GDDyh0AJ+vOQHJ9m+oeBnA1tJ5AZU5\r\naQHvRtyWBKkYaEhljhyWr3eu1JjK4mn7/W6Rszveso33987wtIoQ66GpGcX2\r\nmh7y217y/uXz4D3X5PUEBXIbhvAPty71bnTOwE0EXw9x1QEIALdJgAsQ0Jnv\r\nLXwAKoOammWlUQmracK89v1Yc4mFnImtHDHS3pGsbx3DbNGuiz5BhXCdoPDf\r\ngMxlGmJgShy9JAhrhWFXkvsjW/7aO4bM1wU486VPKXb7Av/dcrfHH0ASj4zj\r\n/TYAeubNoxQtxHgyb13LVCW1kh4Oe6s0ac/hKtxogwEvNFY3x+4yfloHH0Ik\r\n9sbLGk0gS03bPABDHMpYk346406f5TuP6UDzb9M90i2cFxbq26svyBzBZ0vY\r\nzfMRuNsm6an0+B/wS6NLYBqsRyxwwCTdrhYS512yBzCHDYJJX0o3OJNe85/0\r\nTqEBO1prgkh3QMfw13/Oxq8PuMsyJpUAEQEAAcLAfAQYAQgADwUCXw9x1QUJ\r\nAAAAAQIbDAAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJARgH\r\n/1KV7JBOS2ZEtO95FrLYnIqI45rRpvT1XArpBPrYLuHtDBwgMcmpiMhhKIZC\r\nFlZkR1W88ENdSkr8Nx81nW+f9JWRR6HuSyom7kOfS2Gdbfwo3bgp48DWr7K8\r\nKV/HHGuqLqd8UfPyDpsBGNx0w7tRo+8vqUbhskquLAIahYCbhEIE8zgy0fBV\r\nhXKFe1FjuFUoW29iEm0tZWX0k2PT5r1owEgDe0g/X1AXgSQyfPRFVDwE3QNJ\r\n1np/Rmygq1C+DIW2cohJOc7tO4gbl11XolsfQ+FU+HewYXy8aAEbrTSRfsff\r\nMvK6tgT9BZ3kzjOxT5ou2SdvTa0eUk8k+zv8OnJJfXA=\r\n=LPeQ\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n',
    // todo all in case needed
    private: '',
    decrypted: '',
    passphrase: '',
    longid: ''
  }
}

type KeypairName = 'rsa1' | 'rsa2' | 'ecc' | 'gpg-dummy' | 'expired';

export const allKeypairNames: KeypairName[] = ['rsa1', 'rsa2', 'ecc', 'gpg-dummy', 'expired'];

export const getKeypairs = (...names: KeypairName[]) => {
  return {
    pubKeys: names.map(name => TEST_KEYS[name].pubKey),
    keys: names.map(name => ({ private: TEST_KEYS[name].private, longid: TEST_KEYS[name].longid, passphrase: TEST_KEYS[name].passphrase })),
    decrypted: names.map(name => TEST_KEYS[name].decrypted),
    longids: names.map(name => TEST_KEYS[name].longid),
  };
}

export const getCompatAsset = async (name: string) => {
  return await readFile(`source/assets/compat/${name}.txt`);
}

export let readFile = (path: string): Promise<Buffer> => new Promise((resolve, reject) => fs.readFile(path, (e, data) => e ? reject(e) : resolve(data)));

export let writeFile = (path: string, data: Buffer): Promise<void> => new Promise((resolve, reject) => fs.writeFile(path, data, e => e ? reject(e) : resolve()));

export let wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
