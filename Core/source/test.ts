/* © 2016-present FlowCrypt a. s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

// @ts-ignore - this way we can test the Xss class directly as well
global.dereq_html_sanitize = require("sanitize-html");
// @ts-ignore - this way we can test ISO-2201-JP encoding
global.dereq_encoding_japanese = require("encoding-japanese");
(global as any)["emailjs-mime-builder"] = require('../../source/lib/emailjs/emailjs-mime-builder');
(global as any)["emailjs-mime-parser"] = require('../../source/lib/emailjs/emailjs-mime-parser');
(global as any)["iso88592"] = require('../../source/lib/iso-8859-2');

import * as ava from 'ava';

import { allKeypairNames, expectData, expectEmptyJson, expectNoData, getCompatAsset, getHtmlAsset, getKeypairs, parseResponse } from './test/test-utils';

import { Xss } from './platform/xss';
import { expect } from 'chai';
import { openpgp } from './core/pgp';
import { Endpoints } from './mobile-interface/endpoints';

const text = 'some\n汉\ntxt';
const htmlContent = text.replace(/\n/g, '<br />');
const textSpecialChars = '> special <tag> & other\n> second line';
const htmlSpecialChars = Xss.escape(textSpecialChars).replace('\n', '<br />');
const endpoints = new Endpoints();

ava.default('version', async t => {
  const { json, data } = parseResponse(await endpoints.version());
  expect(json).to.have.property('app_version');
  expectNoData(data);
  t.pass();
});

ava.default('generateKey', async t => {
  const { json, data } = parseResponse(await endpoints.generateKey({ variant: 'curve25519', passphrase: 'riruekfhydekdmdbsyd', userIds: [{ email: 'a@b.com', name: 'Him' }] }));
  expect(json.key.private).to.contain('-----BEGIN PGP PRIVATE KEY BLOCK-----');
  expect(json.key.public).to.contain('-----BEGIN PGP PUBLIC KEY BLOCK-----');
  expect(json.key.isFullyEncrypted).to.be.true;
  expect(json.key.isFullyDecrypted).to.be.false;
  expect(json.key.algo).to.deep.equal({ algorithm: 'eddsa', curve: 'ed25519', algorithmId: 22 });
  expectNoData(data);
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name != 'expired' && name != 'revoked')) {
  ava.default(`encryptMsg -> parseDecryptMsg (${keypairName})`, async t => {
    const content = 'hello\nwrld';
    const { pubKeys, keys } = getKeypairs(keypairName);
    const { data: encryptedMsg, json: encryptJson } = parseResponse(await endpoints.encryptMsg({ pubKeys }, [Buffer.from(content, 'utf8')]));
    expectEmptyJson(encryptJson);
    expectData(encryptedMsg, 'armoredMsg');
    const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys }, [encryptedMsg]));
    expect(decryptJson).to.deep.equal({ text: content, replyType: 'encrypted' });
    expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
    t.pass();
  });
}

ava.default('composeEmail format:plain -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { keys } = getKeypairs('rsa1');
  const req = { format: 'plain', text: content, to: ['some@to.com'], cc: ['some@cc.com'], bcc: [], from: 'some@from.com', subject: 'a subj' };
  const { data: plainMimeMsg, json: composeEmailJson } = parseResponse(await endpoints.composeEmail(req));
  expectEmptyJson(composeEmailJson);
  const plainMimeStr = plainMimeMsg.toString();
  expect(plainMimeStr).contains('To: some@to.com');
  expect(plainMimeStr).contains('From: some@from.com');
  expect(plainMimeStr).contains('Subject: a subj');
  expect(plainMimeStr).contains('Cc: some@cc.com');
  expect(plainMimeStr).contains('Date: ');
  expect(plainMimeStr).contains('MIME-Version: 1.0');
  const { data: blocks, json: parseJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [plainMimeMsg]));
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
  const { data: mimeMsgReply, json } = parseResponse(await endpoints.composeEmail(req));
  expectEmptyJson(json);
  const mimeMsgReplyStr = mimeMsgReply.toString();
  expect(mimeMsgReplyStr).contains('In-Reply-To: <originalmsg@from.com>');
  expect(mimeMsgReplyStr).contains('References: <originalmsg@from.com>');
  t.pass();
});

ava.default('composeEmail format:plain with attachment', async t => {
  const content = 'hello\nwrld';
  const req = { format: 'plain', text: content, to: ['some@to.com'], cc: ['some@cc.com'], bcc: [], from: 'some@from.com', subject: 'a subj', atts: [{ name: 'sometext.txt', type: 'text/plain', base64: Buffer.from('hello, world!!!').toString('base64') }] };
  const { data: plainMimeMsg, json: composeEmailJson } = parseResponse(await endpoints.composeEmail(req));
  expectEmptyJson(composeEmailJson);
  const plainMimeStr = plainMimeMsg.toString();
  expect(plainMimeStr).contains('To: some@to.com');
  expect(plainMimeStr).contains('From: some@from.com');
  expect(plainMimeStr).contains('Subject: a subj');
  expect(plainMimeStr).contains('Cc: some@cc.com');
  expect(plainMimeStr).contains('Date: ');
  expect(plainMimeStr).contains('MIME-Version: 1.0');
  expect(plainMimeStr).contains('sometext.txt');
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
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [Buffer.from(mime, 'utf8')]));
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
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [Buffer.from(mime, 'utf8')]));
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'plain', subject: 'plain text with special chars' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in encrypted pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: false }, [await getCompatAsset('direct-encrypted-pgpmime-special-chars')]));
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'encrypted', subject: 'direct encrypted pgpmime special chars' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: htmlSpecialChars }]);
  t.pass();
});

ava.default('parseDecryptMsg unescaped special characters in encrypted text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: false }, [await getCompatAsset('direct-encrypted-text-special-chars')]));
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
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [Buffer.from(mime, 'utf8')]));
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
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: false }, [Buffer.from(mime, 'utf8')]));
  expect(decryptJson).deep.equal({ text: `Standard message\n\nsigned inline\n\nshould easily verify\nThis is email footer`, replyType: 'plain' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'gray', htmlContent: 'Standard message<br /><br />signed inline<br /><br />should easily verify<br />This is email footer' }]);
  t.pass();
});

ava.default('composeEmail format:encrypt-inline -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { pubKeys, keys } = getKeypairs('rsa1');
  const req = { pubKeys, format: 'encrypt-inline', text: content, to: ['encrypted@to.com'], cc: [], bcc: [], from: 'encr@from.com', subject: 'encr subj' };
  const { data: encryptedMimeMsg, json: encryptJson } = parseResponse(await endpoints.composeEmail(req));
  expectEmptyJson(encryptJson);
  const encryptedMimeStr = encryptedMimeMsg.toString();
  expect(encryptedMimeStr).contains('To: encrypted@to.com');
  expect(encryptedMimeStr).contains('MIME-Version: 1.0');
  expectData(encryptedMimeMsg, 'armoredMsg'); // armored msg block should be contained in the mime message
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [encryptedMimeMsg]));
  expect(decryptJson).deep.equal({ text: content, replyType: 'encrypted', subject: 'encr subj' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
  t.pass();
});

ava.default('composeEmail format:encrypt-inline with attachment', async t => {
  const content = 'hello\nwrld';
  const { pubKeys } = getKeypairs('rsa1');
  const req = { pubKeys, format: 'encrypt-inline', text: content, to: ['encrypted@to.com'], cc: [], bcc: [], from: 'encr@from.com', subject: 'encr subj', atts: [{ name: 'topsecret.txt', type: 'text/plain', base64: Buffer.from('hello, world!!!').toString('base64') }] };
  const { data: encryptedMimeMsg, json: encryptJson } = parseResponse(await endpoints.composeEmail(req));
  expectEmptyJson(encryptJson);
  const encryptedMimeStr = encryptedMimeMsg.toString();
  expect(encryptedMimeStr).contains('To: encrypted@to.com');
  expect(encryptedMimeStr).contains('MIME-Version: 1.0');
  expect(encryptedMimeStr).contains('topsecret.txt.pgp');
  expectData(encryptedMimeMsg, 'armoredMsg'); // armored msg block should be contained in the mime message
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name != 'expired' && name != 'revoked')) {
  ava.default(`encryptFile -> decryptFile ${keypairName}`, async t => {
    const { pubKeys, keys } = getKeypairs(keypairName);
    const name = 'myfile.txt';
    const content = Buffer.from([10, 20, 40, 80, 160, 0, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
    const { data: encryptedFile, json: encryptJson } = parseResponse(await endpoints.encryptFile({ pubKeys, name }, [content]));
    expectEmptyJson(encryptJson);
    expectData(encryptedFile);
    const { data: decryptedContent, json: decryptJson } = parseResponse(await endpoints.decryptFile({ keys }, [encryptedFile]));
    expect(decryptJson).to.deep.equal({ decryptSuccess: { name } });
    expectData(decryptedContent, 'binary', content);
    t.pass();
  });
}

ava.default('parseDateStr', async t => {
  const { data, json } = parseResponse(await endpoints.parseDateStr({ dateStr: 'Sun, 10 Feb 2019 07:08:20 -0800' }));
  expect(json).to.deep.equal({ timestamp: '1549811300000' });
  expectNoData(data);
  t.pass();
});

ava.default('gmailBackupSearch', async t => {
  const { data, json } = parseResponse(await endpoints.gmailBackupSearch({ acctEmail: 'test@acct.com' }));
  expect(json).to.deep.equal({ query: 'from:test@acct.com to:test@acct.com (subject:"Your FlowCrypt Backup" OR subject: "Your CryptUp Backup" OR subject: "All you need to know about CryptUP (contains a backup)" OR subject: "CryptUP Account Backup") -is:spam' });
  expectNoData(data);
  t.pass();
});

ava.default('isEmailValid - true', async t => {
  const { data, json } = parseResponse(await endpoints.isEmailValid({ email: 'test@acct.com' }));
  expect(json).to.deep.equal({ valid: true });
  expectNoData(data);
  t.pass();
});

ava.default('isEmailValid - false', async t => {
  const { data, json } = parseResponse(await endpoints.isEmailValid({ email: 'testacct.com' }));
  expect(json).to.deep.equal({ valid: false });
  expectNoData(data);
  t.pass();
});

ava.default('parseKeys', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('rsa1');
  const { data, json } = parseResponse(await endpoints.parseKeys({}, [Buffer.from(pubkey)]));
  expect(json).to.deep.equal({
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
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
        "lastModified": 1543592161,
        "revoked": false
      }
    ]
  });
  expectNoData(data);
  t.pass();
});

ava.default('parseKeys - expiration and date last updated', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('expired');
  const { data, json } = parseResponse(await endpoints.parseKeys({}, [Buffer.from(pubkey)]));
  expect(json).to.deep.equal({
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBF8PcdUBCADi8no6T4Bd9Ny5COpbheBuPWEyDOedT2EVeaPrfutB1D8i\r\nCP6Rf1cUvs/qNUX/O7HQHFpgFuW2uOY4OU5cvcrwmNpOxT3pPt2cavxJMdJo\r\nfwEvloY3OfY7MCqdAj5VUcFGMhubfV810V2n5pf2FFUNTirksT6muhviMymy\r\nuWZLdh0F4WxrXEon7k3y2dZ3mI4xsG+Djttb6hj3gNr8/zNQQnTmVjB0mmpO\r\nFcGUQLTTTYMngvVMkz8/sh38trqkVGuf/M81gkbr1egnfKfGz/4NT3qQLjin\r\nnA8In2cSFS/MipIV14gTfHQAICFIMsWuW/xkaXUqygvAnyFa2nAQdgELABEB\r\nAAHNKDxhdXRvLnJlZnJlc2guZXhwaXJlZC5rZXlAcmVjaXBpZW50LmNvbT7C\r\nwJMEEAEIACYFAl8PcdUFCQAAAAEGCwkHCAMCBBUICgIEFgIBAAIZAQIbAwIe\r\nAQAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJIvQIALG8TGMN\r\nYB4CRouMJawNCLui6Fx4Ba1ipPTaqlJPybLoe6z/WVZwAA9CmbjkCIk683pp\r\nmGQ3GXv7f8Sdk7DqhEhfZ7JtAK/Uw2VZqqIryNrrB0WV3EUHsENCOlq0YJod\r\nLqtkqgl83lCNDIkeoQwq4IyrgC8wsPgF7YMpxxQLONJvChZxSdCDjnfX3kvO\r\nZsLYFiKnNlX6wyrKAQxWnxxYhglMf0GDDyh0AJ+vOQHJ9m+oeBnA1tJ5AZU5\r\naQHvRtyWBKkYaEhljhyWr3eu1JjK4mn7/W6Rszveso33987wtIoQ66GpGcX2\r\nmh7y217y/uXz4D3X5PUEBXIbhvAPty71bnTOwE0EXw9x1QEIALdJgAsQ0Jnv\r\nLXwAKoOammWlUQmracK89v1Yc4mFnImtHDHS3pGsbx3DbNGuiz5BhXCdoPDf\r\ngMxlGmJgShy9JAhrhWFXkvsjW/7aO4bM1wU486VPKXb7Av/dcrfHH0ASj4zj\r\n/TYAeubNoxQtxHgyb13LVCW1kh4Oe6s0ac/hKtxogwEvNFY3x+4yfloHH0Ik\r\n9sbLGk0gS03bPABDHMpYk346406f5TuP6UDzb9M90i2cFxbq26svyBzBZ0vY\r\nzfMRuNsm6an0+B/wS6NLYBqsRyxwwCTdrhYS512yBzCHDYJJX0o3OJNe85/0\r\nTqEBO1prgkh3QMfw13/Oxq8PuMsyJpUAEQEAAcLAfAQYAQgADwUCXw9x1QUJ\r\nAAAAAQIbDAAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJARgH\r\n/1KV7JBOS2ZEtO95FrLYnIqI45rRpvT1XArpBPrYLuHtDBwgMcmpiMhhKIZC\r\nFlZkR1W88ENdSkr8Nx81nW+f9JWRR6HuSyom7kOfS2Gdbfwo3bgp48DWr7K8\r\nKV/HHGuqLqd8UfPyDpsBGNx0w7tRo+8vqUbhskquLAIahYCbhEIE8zgy0fBV\r\nhXKFe1FjuFUoW29iEm0tZWX0k2PT5r1owEgDe0g/X1AXgSQyfPRFVDwE3QNJ\r\n1np/Rmygq1C+DIW2cohJOc7tO4gbl11XolsfQ+FU+HewYXy8aAEbrTSRfsff\r\nMvK6tgT9BZ3kzjOxT5ou2SdvTa0eUk8k+zv8OnJJfXA=\r\n=LPeQ\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
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
        "lastModified": 1594847701,
        "revoked": false
      }
    ]
  });
  expectNoData(data);
  t.pass();
});

ava.default('parseKeys - revoked', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('revoked');
  const { data, json } = parseResponse(await endpoints.parseKeys({}, [Buffer.from(pubkey)]));
  expect(json).to.deep.equal({
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxjMEYW8BThYJKwYBBAHaRw8BAQdAYtEoS4d+3cwQWXcs3lvMQueypexTYai7\r\nuXQmxqyOoKrCjAQgFgoAHQUCYW8CLBYhBDkxt0E9uy+mDO+Fzl8Vl4kQoXgK\r\nACEJEF8Vl4kQoXgKFiEEOTG3QT27L6YM74XOXxWXiRCheAqk5AEApn8X3Oe7\r\nEFgdfo5lkgh6ubpmgyRUpfYHkQE2/S6K+T0BAPGs2py515aUVAgiRy7bJuoY\r\nDKKbOPL1Npd0bgenKgMGzRVyZXZvZWtkQGZsb3djcnlwdC5jb23CXgQTFgoA\r\nBgUCYW8BawAKCRBfFZeJEKF4ChD/AP9gdm4riyAzyGhD4P8ZGW3GtREk56sW\r\nRBB3A/+RUX+qbAEA3FWCs2bUl6pmasXP8QAi0/zoruZiShR2Y2mVAM3T1ATN\r\nFXJldm9rZWRAZmxvd2NyeXB0LmNvbcJeBBMWCgAGBQJhbwFrAAoJEF8Vl4kQ\r\noXgKecoBALdrD8nkptLlT8Dg4cF+3swfY1urlbdEfEvIjN60HRDLAP4w3qeS\r\nzZ+OyuqPFaw7dM2KOu4++WigtbxRpDhpQ9U8BQ==\r\n=bMwq\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
        "users": ["revoekd@flowcrypt.com", "revoked@flowcrypt.com"],
        "ids": [{ "fingerprint": "3931B7413DBB2FA60CEF85CE5F15978910A1780A", "longid": "5F15978910A1780A", "shortid": "10A1780A", "keywords": "GALLERY PROTECT TIME CANDY BLEAK ACCESS" }],
        "algo": { "algorithm": "eddsa", "curve": "ed25519", "algorithmId": 22 },
        "created": 1634664782,
        "lastModified": 1634664811,
        "revoked": true
      }
    ]
  });
  expectNoData(data);
  t.pass();
});

ava.default('decryptKey', async t => {
  const { keys: [key] } = getKeypairs('rsa1');
  const { data, json } = parseResponse(await endpoints.decryptKey({ armored: key.private, passphrases: [key.passphrase] }));
  const { keys: [decryptedKey] } = await openpgp.key.readArmored(json.decryptedKey);
  expect(decryptedKey.isFullyDecrypted()).to.be.true;
  expect(decryptedKey.isFullyEncrypted()).to.be.false;
  expectNoData(data);
  t.pass();
});

ava.default('encryptKey', async t => {
  const passphrase = 'this is some pass phrase';
  const { decrypted: [decryptedKey] } = getKeypairs('rsa1');
  const { data, json } = parseResponse(await endpoints.encryptKey({ armored: decryptedKey, passphrase }));
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
  const { json } = parseResponse(await endpoints.decryptKey({ armored: key.private, passphrases: [key.passphrase] }));
  const { keys: [decryptedKey] } = await openpgp.key.readArmored(json.decryptedKey);
  expect(decryptedKey.isFullyEncrypted()).to.be.false;
  expect(decryptedKey.isFullyDecrypted()).to.be.true;
  const { json: json2 } = parseResponse(await endpoints.encryptKey({ armored: decryptedKey.armor(), passphrase: 'another pass phrase' }));
  const { keys: [reEncryptedKey] } = await openpgp.key.readArmored(json2.encryptedKey);
  expect(reEncryptedKey.isFullyEncrypted()).to.be.true;
  expect(reEncryptedKey.isFullyDecrypted()).to.be.false;
  const { json: json3 } = parseResponse(await endpoints.decryptKey({ armored: reEncryptedKey.armor(), passphrases: ['another pass phrase'] }));
  const { keys: [reDecryptedKey] } = await openpgp.key.readArmored(json3.decryptedKey);
  expect(reDecryptedKey.isFullyEncrypted()).to.be.false;
  expect(reDecryptedKey.isFullyDecrypted()).to.be.true;
  t.pass();
});

ava.default('parseDecryptMsg compat direct-encrypted-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys }, [await getCompatAsset('direct-encrypted-text')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted' });
  t.pass();
});

ava.default('parseDecryptMsg compat direct-encrypted-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys }, [await getCompatAsset('direct-encrypted-pgpmime')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'direct encrypted pgpmime' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-plain')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain-iso-2201-jp', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-plain-iso-2201-jp')]));
  const msg = 'Dear Tomas,\n    \nWe\'ve sent you a new message about your app, ' +
    'Enterprise FlowCrypt, app Apple ID: 1591462989.    To view or reply to the ' +
    'message, go to Resolution Center in App Store Connect.\n    \nBest regards,\n' +
    '    App Store Review\n';
  expect(decryptJson.text).to.contain(msg);
  expect(decryptJson.subject).to.eq('New Message from App Store Review Regarding Enterprise FlowCrypt');
  expect(decryptJson.replyType).to.eq('plain');
  const html = '<p>Dear Tomas,</p> <p>We\'ve sent you a new message about your app, Enterprise FlowCrypt, app Apple ID: 1591462989. To view or reply to the message, go to <a href=\"https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/1591462989/platform/ios/versions/844846907/resolutioncenter\">Resolution Center</a> in App Store Connect.</p> <p>Best regards,<br /> App Store Review</p>';
  const blocksObj = JSON.parse(blocks.toString().replace(/\\n/g, '').replace(/\s+/g, ' '));
  expect(blocksObj.type).eq('plainHtml');
  expect(blocksObj.complete).eq(true);
  expect(blocksObj.content).contains(html);
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-encrypted-inline-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-encrypted-inline-text')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline text' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-encrypted-inline-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-encrypted-inline-pgpmime')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline pgpmime' });
  t.pass();
});

ava.default('zxcvbnStrengthBar', async t => {
  const { data, json } = parseResponse(await endpoints.zxcvbnStrengthBar({ guesses: 88946283684265, purpose: 'passphrase' }));
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
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-encrypted-inline-text-2')]));
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrytped inline text 2' });
  t.pass();
});

ava.default('parseDecryptMsg - decryptErr wrong key when dencrypting content', async t => {
  const { keys } = getKeypairs('rsa2'); // intentional key mismatch
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys }, [await getCompatAsset('direct-encrypted-text')]));
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

ava.default('decryptFile - decryptErr wrong key when decrypting attachment', async t => {
  const jsonReq = { "keys": [{ "private": "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxcaGBFn7qV4BEACgKfufG6yseRP9jKXZ1zrM5sQtkGWiKLks1799m0KwIYuA\r\nQyYvw6cIWbM2dcuBNOzYHsLqluqoXaCDbUpK8wI\/xnH\/9ZHDyomk0ASdyI0K\r\nOgn2DrXFySuRlglPmnMQF7vhpnXeflqp9bxQ9m4yiHMS+FQazMvf\/zcrAKKg\r\nhPxcYXC1BJfSub5tj1rY24ARpK91fWOQO6gAFUvpeSiNiKb7C4lmWuLg64UL\r\njLTLXO9P\/2Vs2BBHOACs6u0pmDnFtDnFleGLC5jrL6VvQDp3ekEvcqcfC5MV\r\nR0N6uVTesRc5hlBtwhbGg4HuI5cFLL+jkRwWcVSluJS9MMtug2eU7FAWIzOC\r\nxWa+Lfb8cHpEg6cidGSxSe49vgKKrysv5PdVfOuXhL63i4TEnKFspOYB8qXy\r\n5n3FkYF\/5CpYN\/HQaoCCxDIXLGp33u03OItadAtQU+qACaGmRhQA9qwe4i+k\r\nLWL3oxoSwQ\/aewb3fVo+K7ygGNltk6poHPcL0dU6VHYe8h2MCEO\/1LR7yVsK\r\nW47B4fgd3huXh868AX3YQn4Pd6mqft4WdcCuRpGJgvJNHq18JvIysDpgsLSq\r\nQF44Z0GOH2vQrnOhJxIWNUKN+QnMy8RN6SZ1UFo4P+vf1z97YI2MfrMLfHB\/\r\nTUnsxS6fGrKhNVxN7ETH69p2rI6F836EZhebLQARAQAB\/gkDCFKqGJu8dd\/2\r\n4HaWToR6\/pB3fRCLZm884bX4Fp4bUutqMtBuETzRxuZs1e8whW28fwMRY68j\r\ngaGUIMXBPxkrEep5rLL3IpAB+T+8mXlVAWLb0TRC8\/UxHMGgqDqZT5I+x9g4\r\ngLlOTqvhwlMPryQdMrFqqvzCyV2DvY410Nv1qBv8wFc2Om8wrVA0JzOXDF3W\r\no4cqj33bykzNMcWjJVd1VFaizz4axJpKc3ulcf+FT6qGS2WFBQ4keROd0iD+\r\nG+mSx144Wx0CKT\/hWC\/RZsZi4+EtSy0\/maQYs9SInOMzYPATop8snQ2di1Zs\r\n5SB5FGsqqRot2WImfk1pkHBGJ0PUDV01giVfoFCIOYO6U8evk2dDY8y9DoWB\r\nU1pwxIRWTVdCcUIZW+Rrhpo4Axq2z\/vXHbi4FJkMc2cO73UK2Uv+HNRfBW2z\r\n3sp5dAweEb0v3Bt4hz2QMdZB7joNray3rIXXnY2sgTqLESXjPB7IsJFiKX1I\r\nTJNTec2+IIvv7cp3AhG1p7\/Y2neLJiu89sNDTK6ZW9zFe1fy1eEMqCFX76bE\r\nztDyahkCJguuNkhV8ctPmaKk\/SmOhWQGxuY4uXo0c2k7\/c5Ns\/cmBhmDZkhE\r\ns3s7P7zkygHRsg2BFgxT3eZ5tSd4i7mfc4vCYzE7clv7f6geyisiv76RU5zX\r\nSL4HXFn7RPhI7iO1evnNrJDPJ0owaa+oCckvbIXSxLk\/IsmIA9O9ixNiBFhF\r\n4\/t8uNTkRswqwML+5s2LtVbc5o1vu5D7QsUgOfSC3KGbQL4+I\/sY4819+XYx\r\nTXI4vjYxksfawdWQ5KpjiY4Y5reG9ZdpHR8Di1l9LTrrFMzrMjou1z1Mt1eo\r\n3SiYmiMQLOkMCF26DE4W+Gtjb9IAU3DpjpV2Yhiqdf+MWwEep+AAOI4QeEpb\r\n6rSJYz5vJ3FQ2SIz5NGMTAwzZHqbUYlEeTUALU23Ynv1uLed6kJyEcE6ZY41\r\nAHpcpIpDRVAUulzloIP0LtyHVZltWrcFlmMRxwZfNXfEehSyUYC88AYUyw2M\r\nu+qTtE0VqaaP3NV6IfDB4gl1R0WSIpy3tOHzOQtZKt1MP+Xvw9OXqoZM3xRJ\r\nlZcwUovf5KcjjrmHhNALhAW+s2NeCmd05zeu82iX1JVQlCnA6+4EyJUOKtXr\r\nbtNXWqqdiPwCEOR1mYigMul3uePA\/7pr7cAp48nedsi3moUNuOL\/HAHTrPPz\r\naUvkfPy\/M2F0KdYcfj76IxoqvIc82U3P7aE3TTVTuKy3PyTQTcx4g+9XMXuv\r\ncK94cnzZnNCkwtJNydpDuXsdsIPYAoQ5qns1OJ4uWggJOh3c+FE7eKaB\/W86\r\nI44u7e3N1yVWBYbmmXd037j\/ohoMeaIfGt5N4FN2ZyvW6SRMsMymBQkCJ\/Dt\r\nrS+CwIYEjC6j7QPFVozJIzC7nwyEe0w\/K++PJOozDHW7Af07BIjUh6D7LFDG\r\n7PBA6Hf8Sy8xNVW265k6yyJ4IgmMfKE0Rh2H7E5f7lRH+0vO6sNybqhlu9L\/\r\nfz3aiIVpA7SJG+AwGx9xbzi3L35b1J3hwZZAeF7xGThcdSKEBncuZkEXJDkX\r\nQLQSdsNq58sgf\/vYC\/2RTW3CXJ07ZcWQdpKfILw+IhkDM41oGmgCFK0bBPBH\r\nZYNduW4bu8xB168rjGusx8WDAaTFxq7+lw2XvZ+42Y5qDOd3icefnvXX2TMn\r\nUVCMoziM2+8SdsIdalpJuRaEWXw9icoz\/mV0LTmTilPaCSmyphVW79XwZsaU\r\noTU2oyqmyWijgUmBe1qjmHG7JbnNO0Zsb3dDcnlwdCBDb21wYXRpYmlsaXR5\r\nIDxmbG93Y3J5cHQuY29tcGF0aWJpbGl0eUBnbWFpbC5jb20+wsF\/BBABCAAp\r\nBQJZ+6ljBgsJBwgDAgkQrawnnJUJMgcEFQgKAgMWAgECGQECGwMCHgEACgkQ\r\nrawnnJUJMgfO5g\/\/audO5E7KXiXIQzqsVfh0RpOS5KwDa8ZNAOzbBjQbfjyv\r\njnvej9pYy+7Pot9NDfGtMEMpWj5uWuPhD1fv2Kv\/uBP4csJqf8Vbs1H1hD4s\r\nD21RrHerM7xCFzIN1XHhkemR7IALNfekrC9TGi4IYYZrZKz\/yK0lCjT8BIro\r\njYUE5CODa8mKPB2BSmJwqNwZxhr0KKnPykrOAZfpArnHEdY3JE54Se6FCxKM\r\nWOtnKBHcwHiSTsX\/nBtK30sCul9j1Wgd1jFRJ244ESJd7M6cBlNrJ6GTZDil\r\nrmpo9nVO0slTwD\/YD6GCyN3r3hJ3IEDnwZK05pL+1trM6718pyWaywfT62vW\r\nzL7pNqk7tIghX+HrvrHVNYs\/G3LnN9m5zlCJMk5wKP+f9olsz3Llupam2auk\r\ng\/h1HXEl3lli9u9QkJkbGaEDWR9UCnH\/xoybpS0mgjVYt0B6jNYvHBLLhuaj\r\nhR+1sjVIIg0kwfxZfQgFXyAL8LWu4nNaSEICUl8hVBWf9V6Xn4VX7JkkWlE3\r\nJEByYiuZkADhSdyklJYkR9fQjUc5AcZsUgOuTXsY4fG0IEryMzrxRw0qgqG1\r\n7rir1uqrvLDrDM18FPWkW2JwGzF0YR5yezvvz3H3rXog+ryEzeZAN48Zwrzv\r\nGRcvEZJFmB1CwTHrW4UykC592pqHR5K4nV7BUTzHxoYEWfupXgEQAK\/GGjyh\r\n3CHg0yGZL5q4LJfn2xABV00RXiwxNyPc\/7YzYgSanBQmzFj3AMJhcFdJx\/Eg\r\n3i0pTr6qbAnwzkYoSm9R9k40PTA9LP4AMBP4uXiwbbkV2Nlo\/RMgmHN4Kquz\r\nwY\/hbNK6ZujFtDGXp2s\/wqtfrfmdDnXuUhnilrOo6NR\/DrtMaEmsXTCfQiZj\r\nnmSkAEJvVUJKihb9C51LzFSWPYEMkjOWo03ZSYJR6NjubjMK2hVEbh8wQ7Wv\r\nvdfssOiwO+gwXw7zibZphCMA7ADVqUeM10q+j+TLGh\/gvpm0ghqjKZsdk2eh\r\nncUlTQhDkwY8JJ5iJ6QThgjYwaAcC0Ake5rA\/7nPn6YMnxlP\/R7Nq651l8SB\r\nozcTzjseOSwearH5tMeKyastTWEIHFAd5rYIEqawpx9F87kLxRhQj9NUQ6uk\r\nmdR66P8elsm9AZdQuaQF53oEQ5zwuUK8+wXqDTC853XtfHsCvxKENP0ZXXvy\r\nqVo2INRNBO5WlSYQjGxoxohs1X+CMAmFSDvbV70dZVf0cQJ9GidocAv70DOH\r\neXBuOiXZBqyGSNjecPl2bFr4A6r5RMnNZDrYieXJOEWUqgaX0uNQacX4Aecm\r\nKiCEyR08XKEPVnnJGUM7mOvhuGdH0ZC03ZUPqLAhfW2cxcsiOeTQ7tc8LLaT\r\nu348PxVsPkN19RbBABEBAAH+CQMI8lDtP6gstovgIoMVwl1\/6RYeAQdxgCEs\r\nuUmcmTJJjO4ycSIKl9fy2mIX+tSJjZ6BtmbadMvKHyllsBBqG4XvQZ9YlLot\r\nRNkYkTS6uB1TydCKL+i9xZT9RLFO\/MEiIe0+4Zn6UICsCeVbYepir8WF0hlP\r\nXfLnlsTK1U3ahWJydQtpakRlC7k7IeDmLcBcHNk2Pgt1\/W1tSDx8OLKqwl7M\r\nIKQ21WylLZ5XrmjhturVHUcHnBvVRDCRgJkXgwflwFP6ve2L0ABQj2mgUCS6\r\nMKlnfysn5Z0H1fAOPR7LEKJ6eKO9UFmzCMTdoMnEKPEtB4BtlbP41RggovNK\r\nwFfyUQWmywxJOp78PzFCAJTdY01eIdTeChMUGcmTPKQL9sN\/qTjfvgg5DJKW\r\nSNraXUSwm8uMLqB\/P6yrKt6I4V0P1YKeOFDNgnDbQS9atg9Nw+opnj6o84CW\r\nu6rUYWlEnyW3AHYcXr5\/X21xkkCKrFoBxeYuF6bVzV3r77Fsxzh3Ec1IijMD\r\nGqyVdMUFI51uQKf1MjXMDkoyPmZQ3v6HUPQIOEC7DQKzcxX3DvoLX0cp4q14\r\nWYDzAi8SJ3CsoW+Lp78F6i2uVE7iCntx2SbR+wcYTFYM0vsZZY43cP9DfHVb\r\nlDM3IL5Sje6I9Df\/evjKpo9ujI2rXro\/AznsXEHHnyH8XXDL3g8TpZLNYT7n\r\nA6EPfwSWy92DRqV9qCiKPYNU8zypPJ6\/jzJ27CIe\/8R5\/FaBN238g3kxQhM+\r\nsEdIvHun5i\/AztkCHochiIyDSKkuIPKBnay7QFtXZ0CxKkubZ+vak+pCFQU3\r\ncFdRx6pIQx71h\/cRF81K+vRILZO9cUJKTHHkEa1NrtCTEOKMsEcBXx\/JH9fG\r\nj5uXj0TCjhqKIjTNe2ADzuxhpGQYqwV6l63uQow0R6XjoGRWg8LXj0mWMrW6\r\ntC4wtPNMswNcNfOFhj\/VJFbY\/lYyZ5my3NY21psC4Ka1r8Livuyb36GFG3vF\r\nIdNAfdYcUeO6ewUUD60AJ7Fgj6tI4AJ3kM4xQyvBZqYKbXnksDJdadm9IGC2\r\nVhOTQ+FVtHQcBhCyyZEFuymhUuRLm9MRtsh1cWib+\/o4liGuPQJylkcu\/7xX\r\n0JKYCjsjnR47l3ocvfGf2fpP3MniROGqYGng+e4wXvKAhsqoo52ecqK9zc\/m\r\nEOoEe4qCs1RFic1HosyfMK1RZrwWhr+rB2i8\/Bt+m95u38zAYfGhxg7\/13kx\r\nWhdyO\/ISddJdwCTaL\/IFYrFNDExqs\/CyeEus+NnHg3h96ZncZiW7x3ntcrHk\r\n0A6QKhoGNldXLCmdM4NW2uGCSDKTW6pSLyiQfRrSQwR1UDp\/Q2qgzPTY0T4T\r\n1oOxWHYLc5E16gP3DaJUAmWHEnaSFdM9k5I0gizD27kE8zHRibZiw0tKbMbw\r\n\/Vj\/97zuVe0Aad99TCJuBRaH5hE9\/VfixPtOgFlVj6MS2QjDM1CsWLc3x7Bp\r\n4Qmmc0\/O7mN16qvYuEACcPlHYjY50o\/o2AQ8mP\/z9L\/CTQ6XDhHBkqdX4MKs\r\nNHVI6gfqo+2LET65gD1hrpoyTSdA1dQJdTJ10raiY+ucOQr2EHfXBKAIOBmL\r\nk\/ZFU\/rr\/0PUhMTZd4BtQd5f3mf9UEJEkk1gK9E3CWliW37niCsrfEw+1yWU\r\nFWBjcCB8U6eSUcOvaddGeps9xlD31n7nKJocyroIBOUSDyQtoiS85ImQvbWI\r\nHtG\/No2yf5prPpDyUsy4g6qMOp8Ivmg2K7icoPBG2y+3D6c8Qj\/h8A9WT2zi\r\nvpoCtMLBaQQYAQgAEwUCWfupZAkQrawnnJUJMgcCGwwACgkQrawnnJUJMge5\r\nuA\/+NA4zV+NWRNIpkyTDPD7FGi4pmFcMUs96Wzcedx244au4ixLLprSOib5e\r\nA1UImjRWptJII6rZJCHVrB\/rFJVQhSHaJQCsSd8K0N1DOOrv4oaGrL9zyzPd\r\nATW8izY9rzIRaNg9Si8DvULfKIheLI429RWDfeYFjFPVJ8n55gwaf28Nptxs\r\nyo4mEWhf+pF\/l8HaQtOzLB82PE4NXwrzf2MogNz3W5BMvcWZo1Vma4Iz1IJf\r\nHdNlZYJO1vMC7u\/7JYAztyH50mXT9Jh6U2jim5OElFRNEUh35E1L2G6XzRdO\r\nJrEXbghF7EO+iekIyRScf2pE+vNBhL2iwnJs+ChgFDFIGnR+Zjwl3rG8mux0\r\niykse5vOToid8SEZ16nu7WF9b8hIxOrM7NBAIaWVD9oqsw8u+n30Mp0DB+pc\r\n0Mnhy0xjMWdTmLcp+Ur5R2uZ6QCZ0lYzLFYs7ZW4X6mT3TwtGWa7eBNIRiyA\r\nBm5g3jhTi8swQXhv8MtG6eLix8H5\/XDOZS91y6PlUdAjfDS34\/IeMlS8SM1Q\r\nIlBkLHqJ18viQNHqw9iYbf557NA6BVqo3A2OVPyyCVaKRoYH3LTcSEpxMciq\r\nOHsqtYlSo7dRyJOEUQ6bWERIAH5vC95fBLgdqted+a5Kq\/7hx8sfrYdL1lJy\r\ntiL0VgGWS0GVL1cZMUwhvvu8bxI=\r\n=AEi0\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n", "passphrase": "these kind of secrets", "fingerprints": ["E8F0517BA6D7DAB6081C96E4ADAC279C95093207", "F9CEDAA4BE95A0074343E0694B5A2FFCE62D9501"], "longid": "ADAC279C95093207" }, { "passphrase": "these kind of secrets", "longid": "A54D82BE1521D20E", "private": "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: FlowCrypt iOS 0.2 Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxYYEYUsiUhYJKwYBBAHaRw8BAQdAWssVJKjkDqTo78c6oRUWQzBU5EeM1jyt\r\nsIYX7PzZh9b+CQMIqu40tHL3zgrg\/JhJPcK19C\/\/kBprnnfE3M7o8tAH+74S\r\nfzZnOuMvbv+Q5uWis2Y0haCVa18SNRTs8Bb67Ek4CH7iZpc8pM3g1pp41qET\r\n5M04ZTJlIGVudGVycHJpc2UgdGVzdHMgPGUyZS5lbnRlcnByaXNlLnRlc3RA\r\nZmxvd2NyeXB0LmNvbT7CeAQTFgoAIAUCYUsiUgIbAwUWAgMBAAQLCQgHBRUK\r\nCQgLAh4BAhkBAAoJEKVNgr4VIdIOtZQBAMaaKKWBbVD3snNnx43J6++diXsV\r\nM1MYGJf472kUZpJ0AQC6QFgxXl8xdCKFR05Dx0vpN+ntBDi24qgjnZAK+nVt\r\nBMeLBGFLIlISCisGAQQBl1UBBQEBB0ClbuLBK8QIkImodd69kI0+3fEeJpY0\r\nt3+Ap4zIW6FhTQMBCAf+CQMIKzrYuvd5qwLg8KuXvCen\/ZMGv\/zBSLsgT6qS\r\nW6JIlJNqzM7zjMX7Y9jJCtD+uG7kjsf94E2l+KYEwg52XI2KoFv5Ftty9VSV\r\nFf7t+HNpbMJ1BBgWCgAdBQJhSyJSAhsMBRYCAwEABAsJCAcFFQoJCAsCHgEA\r\nCgkQpU2CvhUh0g7FDQD\/fmBVBwzgsSS5r+h2SOstqNx1ptfdwrgKAdplixIO\r\nnJwBAKIqt0+rOa+V\/PNGMflXSUh6aLBLc20LQa85fPf\/0m0B\r\n=zHiO\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n", "fingerprints": ["38100D21F17326E447869DA7A54D82BE1521D20E", "7F7B8485B0EB21E6246D74314F66654A6859D46A"] }], "msgPwd": null }
  const { json: decryptJson } = parseResponse(await endpoints.decryptFile(jsonReq, [await getCompatAsset('direct-encrypted-key-mismatch-file')]));
  expect(decryptJson).to.deep.equal({
    "decryptErr": {
      "success": false,
      "error": {
        "type": "key_mismatch",
        "message": "Missing appropriate key"
      },
      "longids": {
        "message": ["305F81A9AED12035"],
        "matching": [],
        "chosen": [],
        "needPassphrase": []
      },
      "isEncrypted": true
    }
  });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain-html', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-plain-html')]));
  expectData(blocks, 'msgBlocks', [{ frameColor: 'plain', htmlContent: '<p>paragraph 1</p><p>paragraph 2 with <b>bold</b></p><p>paragraph 3 with <em style="color:red">red i</em></p>', rendered: true }]);
  expect(decryptJson).to.deep.equal({ text: `paragraph 1\nparagraph 2 with bold\nparagraph 3 with red i`, replyType: 'plain', subject: 'mime email plain html' });
  t.pass();
});

ava.default('parseDecryptMsg compat mime-email-plain-with-pubkey', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-plain-with-pubkey')]));
  expectData(blocks, 'msgBlocks', [
    { rendered: true, frameColor: 'plain', htmlContent },
    {
      "type": "publicKey",
      "content": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
      "complete": true,
      "keyDetails": {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\r\nComment: Seamlessly send and receive encrypted email\r\n\r\nxsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\r\nZln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\r\nmbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\r\nlxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\r\nct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\r\nniRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\r\nAAHNEFRlc3QgPHRAZXN0LmNvbT7CwH8EEAEIACkFAlwBWOEGCwkHCAMCCRA6\r\nMPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAKCRA6MPTMCpqPENaTB/0faBFR\r\n2k3RM7P427HyZOsZtqEPxuynsLUqmsAAup6LtPhir4CAsb5DSvgYrzC8pbrf\r\njCaodoB7hMXc8RxTbSh+vQc5Su4QwY8sqy7hyMXOGGWsRxnuZ8t8BeEJBIHy\r\nPguXIR+wYvo1eveC+NMxHhTtjoSIn/E4vW0W9j5OlFeTK7HTNCuidIE0Hk2k\r\nXnEEoNO7ztxPPxsHz9g56uMhyAhf3mqKfvUFo/FLLRBOpxLO0kk64yAMcAHm\r\nc6ZI5Fz10y48+hHEv/RFOwfub9asF5NWHltanqyiZ+kHeoaieYJFc6t7Mt3j\r\ng8qxMKTUKAEeCfHt1UJCjp/aIgJRU4JRXgYXzsBNBFwBWOEBB/9nclmx98vf\r\noSpPUccBczvuZxmqk+jY6Id+vBhBFoEhtdTSpaw/JNstf0dTXN8RCFjB0lHt\r\na51llTjSobqcFwAU54/HKDOW3qMVbvadaGILpuCMCxdMgLWlpZdYY7BApv1N\r\n9zpN+iQ2tIrvnUQ312xKOXF/W83NUJ1nTObQYNpsUZLLG2N3kz11HuBS3E9F\r\ngEOYYy1tLT53hs5btqvQ5Jp4Iw5cBoBoTAmv+dPMDKYBroBPwuFeNRIokwLT\r\nrVcxrXajxlXaGXmmGS3PZ00HXq2g7vKIqWliMLLIWFl+LlVb6O8bMeXOT1l0\r\nXSO9GlLOSMDEc7pY26vkmAjbWv7iUWHNABEBAAHCwGkEGAEIABMFAlwBWOEJ\r\nEDow9MwKmo8QAhsMAAoJEDow9MwKmo8QjTcH/1pYXyXW/rpBrDg7w/dXJCfT\r\n8+RVYlhW3kqMxbid7EB8zgGVTDr3us/ki99hc2HjsKbxUqrGBxeh3Mmui7OD\r\nCI8XFeYl7lSDbgU6mZ5J4iXzdR8LNqIib4Horlx/Y24dOuvikSUNpDtFAYfa\r\nbZwxyKa/ihZT1rS1GO3V7tdAB9BJagJqVRssF5g5GBUAX3sxQ2p62HoUxPlJ\r\nOOr4AaCc1na92xScBJL8dtBBRQ5pUZWOjb2UHp9L5QdPaBX8T9ZAieOiTlSt\r\nQxoUfCk7RU0/TnsM3KqFnDFoCzkGxKAmU4LmGtP48qV+v2Jzvl+qcmqYuKtw\r\nH6FWd+EZH07MfdEIiTI=\r\n=wXbX\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n",
        "users": ["Test <t@est.com>"],
        "ids": [
          { "fingerprint": "E76853E128A0D376CAE47C143A30F4CC0A9A8F10", "longid": "3A30F4CC0A9A8F10", "shortid": "0A9A8F10", "keywords": "DEMAND MARBLE CREDIT BENEFIT POTTERY CAPITAL" },
          { "fingerprint": "9EF2F8F36A841C0D5FAB8B0F0BAB9C018B265D22", "longid": "0BAB9C018B265D22", "shortid": "8B265D22", "keywords": "ARM FRIEND ABOUT BIND GRAPE CATTLE" }
        ],
        "algo": { "algorithm": "rsa_encrypt_sign", "bits": 2048, "algorithmId": 1 },
        "created": 1543592161,
        "lastModified": 1543592161,
        "revoked": false
      }
    },
  ]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain with pubkey' });
  t.pass();
});

ava.default('parseDecryptMsg plainAtt', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true }, [await getCompatAsset('mime-email-plain-with-attachment')]));
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
  const dirtyBuf = await getHtmlAsset('leak');
  const clean = Xss.htmlSanitizeKeepBasicTags(dirtyBuf.toString());
  expect(clean).to.not.contain('background');
  expect(clean).to.not.contain('script');
  expect(clean).to.not.contain('style');
  expect(clean).to.not.contain('src=http');
  expect(clean).to.not.contain('src="http');
  t.pass();
});

ava.default('verify encrypted+signed message by providing it correct public key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-encrypted-inline-text-signed')]));
  expect(decryptJson.replyType).equals('encrypted');
  expect(decryptJson.subject).equals('mime email encrypted inline text signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

ava.default('verify encrypted+signed message by providing it one wrong and one correct', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const allPubKeys = [];
  for (const pubkey of pubKeys2) allPubKeys.push(pubkey);
  for (const pubkey of pubKeys) allPubKeys.push(pubkey);
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-encrypted-inline-text-signed')]));
  expect(decryptJson.replyType).equals('encrypted');
  expect(decryptJson.subject).equals('mime email encrypted inline text signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

ava.default('verify encrypted+signed message by providing it only a wrong public key (fail: cannot verify)', async t => {
  const { keys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys2 }, [await getCompatAsset('mime-email-encrypted-inline-text-signed')]));
  expect(decryptJson.replyType).equals('encrypted');
  expect(decryptJson.subject).equals('mime email encrypted inline text signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(null);
  t.pass();
});

ava.default('verify plain-text signed message by providing it correct key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-plain-signed')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

ava.default('verify plain-text signed message by providing it both correct and incorrect keys', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const allPubKeys = [];
  for (const pubkey of pubKeys2) allPubKeys.push(pubkey);
  for (const pubkey of pubKeys) allPubKeys.push(pubkey);
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-plain-signed')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

ava.default('verify plain-text signed message by providing it wrong key (fail: cannot verify)', async t => {
  const { keys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys2 }, [await getCompatAsset('mime-email-plain-signed')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(null);
  t.pass();
});

ava.default('verify plain-text signed message that you edited after signing. This invalidates the signature. With correct key. (fail: signature mismatch)', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-plain-signed-edited')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(false);
  t.pass();
});

ava.default('verify signed message with detached signature by providing it correct key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-plain-signed-detached')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed detached');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

ava.default('throw on not integrity protected message', async t => {
  const { keys, pubKeys } = getKeypairs('flowcrypt.compatibility');
  const { json: decryptJson, data: decryptData } = parseResponse(await endpoints.parseDecryptMsg({ keys, isEmail: true, verificationPubkeys: pubKeys }, [await getCompatAsset('mime-email-not-integrity-protected')]));
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('not integrity protected - should show a warning and not decrypt automatically');
  const blocks = decryptData.toString().split('\n').map(block => JSON.parse(block));
  expect(blocks[1].decryptErr.error.type).equals('no_mdc');
  t.pass();
});
