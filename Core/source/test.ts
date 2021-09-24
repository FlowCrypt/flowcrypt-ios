/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import * as ava from 'ava';

import { allKeypairNames, expectData, expectEmptyJson, expectNoData, getCompatAsset, getKeypairs, request, startNodeCoreInstance, httpGet } from './test/test-utils';

import { Xss } from './platform/xss';
import { expect } from 'chai';
import { openpgp } from './core/pgp';
import { ChildProcess } from 'child_process';
// @ts-ignore - this way we can test the Xss class directly as well
global.dereq_html_sanitize = require("sanitize-html");

const text = 'some\n汉\ntxt';
const htmlContent = text.replace(/\n/g, '<br />');
const textSpecialChars = '> special <tag> & other\n> second line';
const htmlSpecialChars = Xss.escape(textSpecialChars).replace('\n', '<br />');

let nodeProcess: ChildProcess;

ava.before(async t => {
  nodeProcess = await startNodeCoreInstance(t);
  t.pass();
});

ava.default('version', async t => {
  const { json, data } = await request('version', {}, []);
  expect(json).to.have.property('node');
  expectNoData(data);
  t.pass();
});

ava.default('doesnotexist', async t => {
  const { data, err } = await request('doesnotexist', {}, [], false);
  expect(err).to.equal('Error: unknown endpoint: doesnotexist');
  expectNoData(data);
  t.pass();
});

ava.default('generateKey', async t => {
  const { json, data } = await request('generateKey', { variant: 'curve25519', passphrase: 'riruekfhydekdmdbsyd', userIds: [{ email: 'a@b.com', name: 'Him' }] }, []);
  expect(json.key.private).to.contain('-----BEGIN PGP PRIVATE KEY BLOCK-----');
  expect(json.key.public).to.contain('-----BEGIN PGP PUBLIC KEY BLOCK-----');
  expect(json.key.isFullyEncrypted).to.be.true;
  expect(json.key.isFullyDecrypted).to.be.false;
  expect(json.key.algo).to.deep.equal({ algorithm: 'eddsa', curve: 'ed25519', algorithmId: 22 });
  expectNoData(data);
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name != 'expired')) {
  ava.default(`encryptMsg -> parseDecryptMsg (${keypairName})`, async t => {
    const content = 'hello\nwrld';
    const { pubKeys, keys } = getKeypairs(keypairName);
    const { data: encryptedMsg, json: encryptJson } = await request('encryptMsg', { pubKeys }, content);
    expectEmptyJson(encryptJson);
    expectData(encryptedMsg, 'armoredMsg');
    const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys }, encryptedMsg);
    expect(decryptJson).to.deep.equal({ text: content, replyType: 'encrypted' });
    expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
    t.pass();
  });
}

ava.default('composeEmail format:plain -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { keys } = getKeypairs('rsa1');
  const req = { format: 'plain', text: content, to: ['some@to.com'], cc: ['some@cc.com'], bcc: [], from: 'some@from.com', subject: 'a subj' };
  const { data: plainMimeMsg, json: composeEmailJson } = await request('composeEmail', req, []);
  expectEmptyJson(composeEmailJson);
  const plainMimeStr = plainMimeMsg.toString();
  expect(plainMimeStr).contains('To: some@to.com');
  expect(plainMimeStr).contains('From: some@from.com');
  expect(plainMimeStr).contains('Subject: a subj');
  expect(plainMimeStr).contains('Cc: some@cc.com');
  expect(plainMimeStr).contains('Date: ');
  expect(plainMimeStr).contains('MIME-Version: 1.0');
  const { data: blocks, json: parseJson } = await request('parseDecryptMsg', { keys, isEmail: true }, plainMimeMsg);
  expect(parseJson).to.deep.equal({ text: content, replyType: 'plain', subject: 'a subj' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: content.replace(/\n/g, '<br />') }]);
  t.pass();
});

ava.default('composeEmail format:plain (reply)', async t => {
  const replyToMimeMsg = `Content-Type: multipart/mixed;
 boundary="----sinikael-?=_1-15535259519270.930031460416217"
To: some@to.com
From: some@from.com
Subject: Re: original
Date: Mon, 25 Mar 2019 14:59:11 +0000
Message-Id: <originalmsg@from.com>
MIME-Version: 1.0

------sinikael-?=_1-15535259519270.930031460416217
Content-Type: text/plain
Content-Transfer-Encoding: quoted-printable

orig message
------sinikael-?=_1-15535259519270.930031460416217--`
  const req = { format: 'plain', text: 'replying', to: ['some@to.com'], cc: [], bcc: [], from: 'some@from.com', subject: 'Re: original', replyToMimeMsg };
  const { data: mimeMsgReply, json } = await request('composeEmail', req, []);
  expectEmptyJson(json);
  const mimeMsgReplyStr = mimeMsgReply.toString();
  expect(mimeMsgReplyStr).contains('In-Reply-To: <originalmsg@from.com>');
  expect(mimeMsgReplyStr).contains('References: <originalmsg@from.com>');
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in text (originally text/plain)', async t => {
  const mime = `MIME-Version: 1.0
Date: Fri, 6 Sep 2019 10:48:25 +0000
Message-ID: <some@mail.gmail.com>
Subject: plain text with special chars
From: Human at FlowCrypt <human@flowcrypt.com>
To: FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>
Content-Type: text/plain; charset="UTF-8"

${textSpecialChars}`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, mime);
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'plain', subject: 'plain text with special chars' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in text (originally text/html)', async t => {
  const mime = `MIME-Version: 1.0
Date: Fri, 6 Sep 2019 10:48:25 +0000
Message-ID: <some@mail.gmail.com>
Subject: plain text with special chars
From: Human at FlowCrypt <human@flowcrypt.com>
To: FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>
Content-Type: text/html; charset="UTF-8"

${htmlSpecialChars}`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, mime);
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'plain', subject: 'plain text with special chars' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in encrypted pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: false }, await getCompatAsset('direct-encrypted-pgpmime-special-chars'));
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'encrypted', subject: 'direct encrypted pgpmime special chars' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in encrypted text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: false }, await getCompatAsset('direct-encrypted-text-special-chars'));
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'encrypted' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg - plain inline img', async t => {
  const mime = `MIME-Version: 1.0
Date: Sat, 10 Aug 2019 10:45:56 +0000
Message-ID: <CAOWYkBvzHVVsTckiqmCqcz0HFGh8YEG1R_AcR9+cB7tUuYiZtg@mail.gmail.com>
Subject: tiny inline img plain
From: Human at FlowCrypt <human@flowcrypt.com>
To: FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>
Content-Type: multipart/related; boundary="000000000000ee643b058fc0fe65"

--000000000000ee643b058fc0fe65
Content-Type: multipart/alternative; boundary="000000000000ee6439058fc0fe64"

--000000000000ee6439058fc0fe64
Content-Type: text/plain; charset="UTF-8"

Below
[image: image.png]
Above

--000000000000ee6439058fc0fe64
Content-Type: text/html; charset="UTF-8"

<div dir="ltr"><div>Below</div><div><div><img src="cid:ii_jz5exwmh0" alt="image.png" width="16" height="16"><br></div></div><div>Above<br></div></div>

--000000000000ee6439058fc0fe64--
--000000000000ee643b058fc0fe65
Content-Type: image/png; name="image.png"
Content-Disposition: attachment; filename="image.png"
Content-Transfer-Encoding: base64
X-Attachment-Id: ii_jz5exwmh0
Content-ID: <ii_jz5exwmh0>

iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAMFJREFU
OE+lU9sRg0AIZDNpym9rSAumJm0hNfidsgic5w1wGJ1kZ3zgwvI4AQtIAHrq4zKY5uJ715sGP7C4
4BdPnZj1gaRVERBPpYJfUSpoGLeyir2Glg64mxMQg9f6xQbU94zrBDBWgVCBBmecbyGWbcrLgpX+
OkR+L4ShPw3bdtdCnMmZfSig2a+gtcD1R0LyA1mh6OdmsJNnmW0Sfwp75LYevQ5AsUI3g0aKI+ll
Ee3KQbcx28SsnZi9LNO/6/wBmhVJ7HDmOd4AAAAASUVORK5CYII=
--000000000000ee643b058fc0fe65--`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, mime);
  expect(decryptJson).deep.equal({ text: 'Below\n[image: image.png]\nAbove', replyType: 'plain', subject: 'tiny inline img plain' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: '<div><div>Below</div><div><div><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAMFJREFUOE+lU9sRg0AIZDNpym9rSAumJm0hNfidsgic5w1wGJ1kZ3zgwvI4AQtIAHrq4zKY5uJ715sGP7C44BdPnZj1gaRVERBPpYJfUSpoGLeyir2Glg64mxMQg9f6xQbU94zrBDBWgVCBBmecbyGWbcrLgpX+OkR+L4ShPw3bdtdCnMmZfSig2a+gtcD1R0LyA1mh6OdmsJNnmW0Sfwp75LYevQ5AsUI3g0aKI+llEe3KQbcx28SsnZi9LNO/6/wBmhVJ7HDmOd4AAAAASUVORK5CYII=" alt="image.png" /><br /></div></div><div>Above<br /></div></div>' }]);
  t.pass();
});

ava.default('parseDecryptMsg - signed message preserve newlines', async t => {
  const mime = `-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

Standard message

signed inline

should easily verify
This is email footer
-----BEGIN PGP SIGNATURE-----
Version: FlowCrypt 5.0.4 Gmail Encryption flowcrypt.com
Comment: Seamlessly send, receive and search encrypted email

wsFcBAEBCAAQBQJZ+74YCRAGylU+wkVdcAAAfAkQAKYwTCQUX4K26jwzKPG0
ue6+jSygpkNlsHqfo7ZU0SYbvao0xEo1QQPy9zVW7zP39UAJZkN5EpIARBzF
671AA3s0KtknLt0AYfiTJdkqTihRjJZHBHQcxkkajws+3Br8oBieB4zi19GJ
oOqjyi2uxl7By5CSP238B6CXBTgaYkh/7TpYJDgFzuhtXtx0aWBP9h7TgEYN
AYNmtGItT6W2Q/JoB29cVsxyugVsQhdfM8DA5MpEZY2Zk/+UHXN0L45rEJFj
8HJkR83voiwAe6DdkLQHbYfVytSDZN+K80xN/VCQfdd7+HKpKbftIig0cXmr
+OsoDMGvPWkGEqJRh57bezWfz6jnkSSJSX9mXFG6KSJ2xuj30nPXsl1Wn1Xv
wR5T3L2kDusluFERiq0NnKDwAveHZIzh7xtjmYRlGVNujta0qTQXTyajxDpu
gZIqZKjDVZp7CjKYYPzvgUsihPzlgyqAodkMpl/IhYidPMB135lV4BBKHrF2
Urbb2tXMHa6rEZoj6jbS0uw/O1fSBJASYflrJ1M8YLsFCwBHpMWWL38ojbmK
i1EHYIU8A/y0qELPpKorgnLNKh8t05a01nrUWd/eXDKS1bbGlLeR6R/YvOM5
ADjvgywpiGmrwdehioKtS0SrHRvExYx8ory0iLo0cLGERArZ3jycF8F+S2Xp
5BnI
=F2om
-----END PGP SIGNATURE-----`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: false }, mime);
  expect(decryptJson).deep.equal({ text: `Standard message\n\nsigned inline\n\nshould easily verify\nThis is email footer`, replyType: 'plain' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'gray', htmlContent: 'Standard message<br /><br />signed inline<br /><br />should easily verify<br />This is email footer' }]);
  t.pass();
});

ava.default('composeEmail format:encrypt-inline -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { pubKeys, keys } = getKeypairs('rsa1');
  const req = { pubKeys, format: 'encrypt-inline', text: content, to: ['encrypted@to.com'], cc: [], bcc: [], from: 'encr@from.com', subject: 'encr subj' };
  const { data: encryptedMimeMsg, json: encryptJson } = await request('composeEmail', req, []);
  expectEmptyJson(encryptJson);
  const encryptedMimeStr = encryptedMimeMsg.toString();
  expect(encryptedMimeStr).contains('To: encrypted@to.com');
  expect(encryptedMimeStr).contains('MIME-Version: 1.0');
  expectData(encryptedMimeMsg, 'armoredMsg'); // armored msg block should be contained in the mime message
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, encryptedMimeMsg);
  expect(decryptJson).deep.equal({ text: content, replyType: 'encrypted', subject: 'encr subj' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name != 'expired')) {
  ava.default(`encryptFile -> decryptFile ${keypairName}`, async t => {
    const { pubKeys, keys } = getKeypairs(keypairName);
    const name = 'myfile.txt';
    const content = Buffer.from([10, 20, 40, 80, 160, 0, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
    const { data: encryptedFile, json: encryptJson } = await request('encryptFile', { pubKeys, name }, content);
    expectEmptyJson(encryptJson);
    expectData(encryptedFile);
    const { data: decryptedContent, json: decryptJson } = await request('decryptFile', { keys }, encryptedFile);
    expect(decryptJson).to.deep.equal({ success: true, name });
    expectData(decryptedContent, 'binary', content);
    t.pass();
  });
}

ava.default('parseDateStr', async t => {
  const { data, json } = await request('parseDateStr', { dateStr: 'Sun, 10 Feb 2019 07:08:20 -0800' }, []);
  expect(json).to.deep.equal({ timestamp: '1549811300000' });
  expectNoData(data);
  t.pass();
});

ava.default('gmailBackupSearch', async t => {
  const { data, json } = await request('gmailBackupSearch', { acctEmail: 'test@acct.com' }, []);
  expect(json).to.deep.equal({ query: 'from:test@acct.com to:test@acct.com (subject:"Your FlowCrypt Backup" OR subject: "Your CryptUp Backup" OR subject: "All you need to know about CryptUP (contains a backup)" OR subject: "CryptUP Account Backup") -is:spam' });
  expectNoData(data);
  t.pass();
});

ava.default('isEmailValid - true', async t => {
  const { data, json } = await request('isEmailValid', { email: 'test@acct.com' }, []);
  expect(json).to.deep.equal({ valid: true });
  expectNoData(data);
  t.pass();
});

ava.default('isEmailValid - false', async t => {
  const { data, json } = await request('isEmailValid', { email: 'testacct.com' }, []);
  expect(json).to.deep.equal({ valid: false });
  expectNoData(data);
  t.pass();
});

ava.default('parseKeys', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('rsa1');
  const { data, json } = await request('parseKeys', {}, Buffer.from(pubkey));
  expect(json).to.deep.equal({
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt 0.0.1-dev Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
        "users": [
          "Test <t@est.com>"
        ],
        "ids": [
          { "fingerprint": "E76853E128A0D376CAE47C143A30F4CC0A9A8F10", "longid": "3A30F4CC0A9A8F10", "shortid": "0A9A8F10", "keywords": "DEMAND MARBLE CREDIT BENEFIT POTTERY CAPITAL" },
          { "fingerprint": "9EF2F8F36A841C0D5FAB8B0F0BAB9C018B265D22", "longid": "0BAB9C018B265D22", "shortid": "8B265D22", "keywords": "ARM FRIEND ABOUT BIND GRAPE CATTLE" }
        ],
        "algo": {
          "algorithm": "rsa_encrypt_sign",
          "bits": 2048,
          "algorithmId": 1
        },
        "created": 1543592161,
        "lastModified": 1543592161
      }
    ]
  });
  expectNoData(data);
  t.pass();
});

ava.default('parseKeys - expiration and date last updated', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('expired');
  const { data, json } = await request('parseKeys', {}, Buffer.from(pubkey));
  expect(json).to.deep.equal({
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt 0.0.1-dev Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBF8PcdUBCADi8no6T4Bd9Ny5COpbheBuPWEyDOedT2EVeaPrfutB1D8i\r\nCP6Rf1cUvs/qNUX/O7HQHFpgFuW2uOY4OU5cvcrwmNpOxT3pPt2cavxJMdJo\r\nfwEvloY3OfY7MCqdAj5VUcFGMhubfV810V2n5pf2FFUNTirksT6muhviMymy\r\nuWZLdh0F4WxrXEon7k3y2dZ3mI4xsG+Djttb6hj3gNr8/zNQQnTmVjB0mmpO\r\nFcGUQLTTTYMngvVMkz8/sh38trqkVGuf/M81gkbr1egnfKfGz/4NT3qQLjin\r\nnA8In2cSFS/MipIV14gTfHQAICFIMsWuW/xkaXUqygvAnyFa2nAQdgELABEB\r\nAAHNKDxhdXRvLnJlZnJlc2guZXhwaXJlZC5rZXlAcmVjaXBpZW50LmNvbT7C\r\nwJMEEAEIACYFAl8PcdUFCQAAAAEGCwkHCAMCBBUICgIEFgIBAAIZAQIbAwIe\r\nAQAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJIvQIALG8TGMN\r\nYB4CRouMJawNCLui6Fx4Ba1ipPTaqlJPybLoe6z/WVZwAA9CmbjkCIk683pp\r\nmGQ3GXv7f8Sdk7DqhEhfZ7JtAK/Uw2VZqqIryNrrB0WV3EUHsENCOlq0YJod\r\nLqtkqgl83lCNDIkeoQwq4IyrgC8wsPgF7YMpxxQLONJvChZxSdCDjnfX3kvO\r\nZsLYFiKnNlX6wyrKAQxWnxxYhglMf0GDDyh0AJ+vOQHJ9m+oeBnA1tJ5AZU5\r\naQHvRtyWBKkYaEhljhyWr3eu1JjK4mn7/W6Rszveso33987wtIoQ66GpGcX2\r\nmh7y217y/uXz4D3X5PUEBXIbhvAPty71bnTOwE0EXw9x1QEIALdJgAsQ0Jnv\r\nLXwAKoOammWlUQmracK89v1Yc4mFnImtHDHS3pGsbx3DbNGuiz5BhXCdoPDf\r\ngMxlGmJgShy9JAhrhWFXkvsjW/7aO4bM1wU486VPKXb7Av/dcrfHH0ASj4zj\r\n/TYAeubNoxQtxHgyb13LVCW1kh4Oe6s0ac/hKtxogwEvNFY3x+4yfloHH0Ik\r\n9sbLGk0gS03bPABDHMpYk346406f5TuP6UDzb9M90i2cFxbq26svyBzBZ0vY\r\nzfMRuNsm6an0+B/wS6NLYBqsRyxwwCTdrhYS512yBzCHDYJJX0o3OJNe85/0\r\nTqEBO1prgkh3QMfw13/Oxq8PuMsyJpUAEQEAAcLAfAQYAQgADwUCXw9x1QUJ\r\nAAAAAQIbDAAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJARgH\r\n/1KV7JBOS2ZEtO95FrLYnIqI45rRpvT1XArpBPrYLuHtDBwgMcmpiMhhKIZC\r\nFlZkR1W88ENdSkr8Nx81nW+f9JWRR6HuSyom7kOfS2Gdbfwo3bgp48DWr7K8\r\nKV/HHGuqLqd8UfPyDpsBGNx0w7tRo+8vqUbhskquLAIahYCbhEIE8zgy0fBV\r\nhXKFe1FjuFUoW29iEm0tZWX0k2PT5r1owEgDe0g/X1AXgSQyfPRFVDwE3QNJ\r\n1np/Rmygq1C+DIW2cohJOc7tO4gbl11XolsfQ+FU+HewYXy8aAEbrTSRfsff\r\nMvK6tgT9BZ3kzjOxT5ou2SdvTa0eUk8k+zv8OnJJfXA=\r\n=LPeQ\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
        "users": [
          "<auto.refresh.expired.key@recipient.com>"
        ],
        "ids": [
          {
            "fingerprint": "6D3E09867544EE627F2E928FBEE3A42D9A9C8AC9",
            "longid": "BEE3A42D9A9C8AC9",
            "shortid": "9A9C8AC9",
            "keywords": "SAME BRUSH ARENA CRY SILLY BOMB"
          },
          {
            "fingerprint": "0731F9992FE2152E101E0D37D16EE86BDB129956",
            "longid": "D16EE86BDB129956",
            "shortid": "DB129956",
            "keywords": "SPHERE JAR BRAIN RENEW CIVIL CLIENT"
          }
        ],
        "algo": {
          "algorithm": "rsa_encrypt_sign",
          "bits": 2048,
          "algorithmId": 1
        },
        "created": 1594847701,
        "expiration": 1594847702,
        "lastModified": 1594847701
      }
    ]
  });
  expectNoData(data);
  t.pass();
});

ava.default('decryptKey', async t => {
  const { keys: [key] } = getKeypairs('rsa1');
  const { data, json } = await request('decryptKey', { armored: key.private, passphrases: [key.passphrase] }, Buffer.from([]));
  const { keys: [decryptedKey] } = await openpgp.key.readArmored(json.decryptedKey);
  expect(decryptedKey.isFullyDecrypted()).to.be.true;
  expect(decryptedKey.isFullyEncrypted()).to.be.false;
  expectNoData(data);
  t.pass();
});

ava.default('encryptKey', async t => {
  const passphrase = 'this is some pass phrase';
  const { decrypted: [decryptedKey] } = getKeypairs('rsa1');
  const { data, json } = await request('encryptKey', { armored: decryptedKey, passphrase }, Buffer.from([]));
  const { keys: [encryptedKey] } = await openpgp.key.readArmored(json.encryptedKey);
  expect(encryptedKey.isFullyEncrypted()).to.be.true;
  expect(encryptedKey.isFullyDecrypted()).to.be.false;
  expect(await encryptedKey.decrypt(passphrase)).to.be.true;
  expectNoData(data);
  t.pass();
});

ava.default('decryptKey gpg-dummy', async t => {
  const { keys: [key] } = getKeypairs('gpg-dummy');
  const { keys: [encryptedKey] } = await openpgp.key.readArmored(key.private);
  expect(encryptedKey.isFullyEncrypted()).to.be.true;
  expect(encryptedKey.isFullyDecrypted()).to.be.false;
  const { json } = await request('decryptKey', { armored: key.private, passphrases: [key.passphrase] }, Buffer.from([]));
  const { keys: [decryptedKey] } = await openpgp.key.readArmored(json.decryptedKey);
  expect(decryptedKey.isFullyEncrypted()).to.be.false;
  expect(decryptedKey.isFullyDecrypted()).to.be.true;
  const { json: json2 } = await request('encryptKey', { armored: decryptedKey.armor(), passphrase: 'another pass phrase' }, Buffer.from([]));
  const { keys: [reEncryptedKey] } = await openpgp.key.readArmored(json2.encryptedKey);
  expect(reEncryptedKey.isFullyEncrypted()).to.be.true;
  expect(reEncryptedKey.isFullyDecrypted()).to.be.false;
  const { json: json3 } = await request('decryptKey', { armored: reEncryptedKey.armor(), passphrases: ['another pass phrase'] }, Buffer.from([]));
  const { keys: [reDecryptedKey] } = await openpgp.key.readArmored(json3.decryptedKey);
  expect(reDecryptedKey.isFullyEncrypted()).to.be.false;
  expect(reDecryptedKey.isFullyDecrypted()).to.be.true;
  t.pass();
});

ava.default('parseDecryptMsg compat direct-encrypted-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys }, await getCompatAsset('direct-encrypted-text'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted' });
  t.pass();
});

ava.default('parseDecryptMsg compat direct-encrypted-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys }, await getCompatAsset('direct-encrypted-pgpmime'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'direct encrypted pgpmime' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-plain'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-encrypted-inline-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-encrypted-inline-text'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline text' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-encrypted-inline-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-encrypted-inline-pgpmime'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline pgpmime' });
  t.pass();
});

ava.default('zxcvbnStrengthBar', async t => {
  const { data, json } = await request('zxcvbnStrengthBar', { guesses: 88946283684265, purpose: 'passphrase' }, []);
  expectNoData(data);
  expect(json).to.deep.equal({
    word: {
      match: 'week',
      word: 'poor',
      bar: 30,
      color: 'darkred',
      pass: false
    },
    seconds: 1111829,
    time: '2 weeks',
  });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-encrypted-inline-text-2 Mime-TextEncoder', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-encrypted-inline-text-2'));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrytped inline text 2' });
  t.pass();
});

ava.default('parseDecryptMsg - decryptErr', async t => {
  const { keys } = getKeypairs('rsa2'); // intentional key mismatch
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys }, await getCompatAsset('direct-encrypted-text'), false);
  expectData(blocks, 'msgBlocks', [{
    "type": "decryptErr",
    "content": "-----BEGIN PGP MESSAGE-----\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\nComment: Seamlessly send and receive encrypted email\n\nwcBMAwurnAGLJl0iAQf+I2exIah3XL/zfPozDmVFSLJk4tBFIlIyFfGYcw5W\n+ebOL3Gu/+/oCIIlXrdP0FxIVEYnSEaevmB9p0FfXGpcw4Wr8PBnSubCkn2s\n+V//k6W1Uu915GmiwCgDkLTCP7vEHvwUglNvgAatDtNdJ3xrf2gjOOFiYQnn\n4JSI1msMfL5tmdFCyXm1g4mUe9MdVXfphrXIyvGu1Sufhv+T5FgteDW0c6lM\ng7G6jgX4q5xiT8r2LTxKlxHVlQSqvGlnx/yRXwqBs3PAMiS4u5JlKJX4aKVy\nFyN+gq++tWZC1XCSFzXfAf0rXcoDZ7nEkxdkKQqXgA6LCsFD79FMCtuenvzU\nU9JEAdvmmpGlextZcfCUmGgclQXgowDnjaXy5Uc6Bzmi8AlY/4MFo0Q3bOU4\nkNhLCiXTGNJlFDd0HLz8Cy7YXzLWZ94IuGk=\n=Bvit\n-----END PGP MESSAGE-----\n",
    "decryptErr": {
      "success": false,
      "error": {
        "type": "key_mismatch",
        "message": "Missing appropriate key"
      },
      "longids": {
        "message": ["0BAB9C018B265D22"],
        "matching": [],
        "chosen": [],
        "needPassphrase": []
      },
      "isEncrypted": true
    },
    "complete": true
  }]);
  expect(decryptJson).to.deep.equal({ text: '', replyType: 'plain' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain-html', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-plain-html'));
  expectData(blocks, 'msgBlocks', [{ frameColor: 'plain', htmlContent: '<p>paragraph 1</p><p>paragraph 2 with <b>bold</b></p><p>paragraph 3 with <em style="color:red">red i</em></p>', rendered: true }]);
  expect(decryptJson).to.deep.equal({ text: `paragraph 1\nparagraph 2 with bold\nparagraph 3 with red i`, replyType: 'plain', subject: 'mime email plain html' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain-with-pubkey', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-plain-with-pubkey'));
  expectData(blocks, 'msgBlocks', [
    { rendered: true, frameColor: 'plain', htmlContent },
    {
      "type": "publicKey",
      "content": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt 0.0.1-dev Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
      "complete": true,
      "keyDetails": {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt 0.0.1-dev Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
        "users": ["Test <t@est.com>"],
        "ids": [
          { "fingerprint": "E76853E128A0D376CAE47C143A30F4CC0A9A8F10", "longid": "3A30F4CC0A9A8F10", "shortid": "0A9A8F10", "keywords": "DEMAND MARBLE CREDIT BENEFIT POTTERY CAPITAL" },
          { "fingerprint": "9EF2F8F36A841C0D5FAB8B0F0BAB9C018B265D22", "longid": "0BAB9C018B265D22", "shortid": "8B265D22", "keywords": "ARM FRIEND ABOUT BIND GRAPE CATTLE" }
        ],
        "algo": { "algorithm": "rsa_encrypt_sign", "bits": 2048, "algorithmId": 1 },
        "created": 1543592161,
        "lastModified": 1543592161
      }
    },
  ]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain with pubkey' });
  t.pass();
});

ava.default('parseDecryptMsg plainAtt', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = await request('parseDecryptMsg', { keys, isEmail: true }, await getCompatAsset('mime-email-plain-with-attachment'));
  expectData(blocks, 'msgBlocks', [
    { rendered: true, frameColor: 'plain', htmlContent },
    { 
      type: 'plainAtt',
      content: '',
      complete: true,
      attMeta: {
        name: 'name.txt',
        type: 'text/plain',
        length: 18,
        data: 'ZmlsZSBjb250ZW50IGhlcmUK',
        inline: false,
        cid: '<f_kpu3dty00>'
      } 
    } 
  ]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'plain message with attachment' });
  t.pass();
});

ava.default('can process dirty html without throwing', async t => {
  const dirtyBuf = await httpGet('https://raw.githubusercontent.com/cure53/HTTPLeaks/main/leak.html');
  const clean = Xss.htmlSanitizeKeepBasicTags(dirtyBuf.toUtfStr());
  expect(clean).to.not.contain('background');
  expect(clean).to.not.contain('script');
  expect(clean).to.not.contain('style');
  expect(clean).to.not.contain('src=http');
  expect(clean).to.not.contain('src="http');
  t.pass();
})

ava.after(async t => {
  nodeProcess.kill();
  t.pass();
});
