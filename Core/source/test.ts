/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

/* eslint-disable */
// @ts-ignore - this way we can test the Xss class directly as well
global.dereq_sanitize_html = require("sanitize-html");
// @ts-ignore - this way we can test ISO-2201-JP encoding
global.dereq_encoding_japanese = require("encoding-japanese");
(global as any)["emailjs-mime-builder"] = require('../../source/lib/emailjs/emailjs-mime-builder');
(global as any)["emailjs-mime-parser"] = require('../../source/lib/emailjs/emailjs-mime-parser');
(global as any).iso88592 = require('../../source/lib/iso-8859-2');
/* eslint-enable */

import test from 'ava';

import {
  allKeypairNames, expectData, expectEmptyJson, expectNoData, getCompatAsset,
  getHtmlAsset, getKeypairs, JsonDict
} from './test/test-utils';

import { Xss } from './platform/xss';
import { expect } from 'chai';
import { Endpoints } from './mobile-interface/endpoints';
import { config, decryptKey, PrivateKey, readKey } from 'openpgp';
import { isFullyDecrypted, isFullyEncrypted } from './core/pgp';
import { KeyDetails, PgpKey } from './core/pgp-key';
import { MsgBlock } from './core/msg-block';

const text = 'some\n汉\ntxt';
const htmlContent = text.replace(/\n/g, '<br />');
const textSpecialChars = '> special <tag> & other\n> second line';
const htmlSpecialChars = Xss.escape(textSpecialChars).replace('\n', '<br />');
const endpoints = new Endpoints();

test('version', async t => {
  const { json, data } = await endpoints.version();
  expect(json).to.have.property('app_version');
  expectNoData(data);
  t.pass();
});

test.serial('composeEmail and parseKeys with shouldHideArmorMeta', async t => {
  const { pubKeys } = getKeypairs('rsa1');
  const req = {
    pubKeys, format: 'encryptInline', text: '',
    to: [], cc: [], bcc: [], from: '', subject: ''
  };
  await endpoints.setClientConfiguration({ shouldHideArmorMeta: false });
  expect(config.showComment).eq(true);
  expect(config.showVersion).eq(true);
  const { data: encryptedMimeMsgWithArmorMeta } = await endpoints.composeEmail(req);
  const encryptedMimeStrWithMeta = encryptedMimeMsgWithArmorMeta.toString();
  expect(encryptedMimeStrWithMeta).contains('\nVersion: ');
  expect(encryptedMimeStrWithMeta).contains('Comment: ');
  const { json: jsonWithMeta } = await endpoints.parseKeys({}, [Buffer.from(pubKeys[0])]);
  const firstPubKey = (jsonWithMeta as { keyDetails: KeyDetails[] }).keyDetails[0].public;
  expect(firstPubKey).contains('Version: ');
  expect(firstPubKey).contains('Comment: ');
  await endpoints.setClientConfiguration({ shouldHideArmorMeta: true });
  expect(config.showComment).eq(false);
  expect(config.showVersion).eq(false);
  const { data: encryptedMimeMsgWithoutArmorMeta } = await endpoints.composeEmail(req);
  const encryptedMimeStrWithoutMeta = encryptedMimeMsgWithoutArmorMeta.toString();
  expect(encryptedMimeStrWithoutMeta).to.not.contain('\nVersion: ');
  expect(encryptedMimeStrWithoutMeta).to.not.contain('Comment: ');
  const { json: jsonWithoutMeta } = await endpoints.parseKeys({}, [Buffer.from(pubKeys[0])]);
  const firstPubKeyWithoutMeta = (jsonWithoutMeta as { keyDetails: KeyDetails[] }).keyDetails[0].public;
  expect(firstPubKeyWithoutMeta).to.not.contain('Version: ');
  expect(firstPubKeyWithoutMeta).to.not.contain('Comment: ');
  t.pass();
});

test('generateKey', async t => {
  const { json, data } = await endpoints.generateKey({
    variant: 'curve25519', passphrase: 'riruekfhydekdmdbsyd',
    userIds: [{ email: 'a@b.com', name: 'Him' }]
  });
  expect((json.key as { private: string }).private).to.contain('-----BEGIN PGP PRIVATE KEY BLOCK-----');
  expect((json.key as { public: string }).public).to.contain('-----BEGIN PGP PUBLIC KEY BLOCK-----');
  const key = await readKey({ armoredKey: (json.key as { private: string }).private });
  /* eslint-disable @typescript-eslint/no-unused-expressions */
  expect(isFullyEncrypted(key)).to.be.true;
  expect(isFullyDecrypted(key)).to.be.false;
  /* eslint-enable @typescript-eslint/no-unused-expressions */
  expect((json.key as { algo: string }).algo).to.deep.equal({ algorithm: 'eddsa', curve: 'ed25519', algorithmId: 22 });
  expectNoData(data);
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name !== 'expired' && name !== 'revoked')) {
  test(`encryptMsg -> parseDecryptMsg (${keypairName})`, async t => {
    const content = 'hello\nwrld';
    const { pubKeys, keys } = getKeypairs(keypairName);
    const { data: encryptedMsg, json: encryptJson } =
      await endpoints.encryptMsg({ pubKeys }, [Buffer.from(content, 'utf8')]);
    expectEmptyJson(encryptJson as JsonDict);
    expectData(encryptedMsg, 'armoredMsg');
    const { data: blocks, json: decryptJson } =
      await endpoints.parseDecryptMsg({ keys }, [encryptedMsg]);
    expect(decryptJson).to.deep.equal({ text: content, replyType: 'encrypted' });
    expectData(blocks, 'msgBlocks',
      [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
    t.pass();
  });
}

test(`encryptMsg -> parseDecryptMsg (with password)`, async t => {
  const content = 'hello\nwrld';
  const msgPwd = '123';
  const { data: encryptedMsg, json: encryptJson } =
    await endpoints.encryptMsg({ pubKeys: [], msgPwd }, [Buffer.from(content, 'utf8')]);
  expectEmptyJson(encryptJson as JsonDict);
  expectData(encryptedMsg, 'armoredMsg');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys: [], msgPwd }, [encryptedMsg]);
  expect(decryptJson).to.deep.equal({ text: content, replyType: 'encrypted' });
  expectData(blocks, 'msgBlocks', [
    { rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }
  ]);
  t.pass();
});

test('composeEmail format:plain -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { keys } = getKeypairs('rsa1');
  const req = {
    format: 'plain', text: content, to: ['some@to.com'],
    cc: ['some@cc.com'], bcc: [], from: 'some@from.com', subject: 'a subj'
  };
  const { data: plainMimeMsg, json: composeEmailJson } = await endpoints.composeEmail(req);
  expectEmptyJson(composeEmailJson as JsonDict);
  const plainMimeStr = plainMimeMsg.toString();
  expect(plainMimeStr).contains('To: some@to.com');
  expect(plainMimeStr).contains('From: some@from.com');
  expect(plainMimeStr).contains('Subject: a subj');
  expect(plainMimeStr).contains('Cc: some@cc.com');
  expect(plainMimeStr).contains('Date: ');
  expect(plainMimeStr).contains('MIME-Version: 1.0');
  const { data: blocks, json: parseJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [plainMimeMsg]);
  expect(parseJson).to.deep.equal({ text: content, replyType: 'plain', subject: 'a subj' });
  expectData(blocks, 'msgBlocks',
    [{ rendered: true, frameColor: 'plain', htmlContent: content.replace(/\n/g, '<br />') }]);
  t.pass();
});

test('composeEmail format:plain (reply)', async t => {
  const req = {
    format: 'plain', text: 'replying', to: ['some@to.com'],
    cc: [], bcc: [], from: 'some@from.com', subject: 'Re: original',
    replyToMsgId: 'originalmsg@from.com'
  };
  const { data: mimeMsgReply, json } = await endpoints.composeEmail(req);
  expectEmptyJson(json as JsonDict);
  const mimeMsgReplyStr = mimeMsgReply.toString();
  expect(mimeMsgReplyStr).contains('In-Reply-To: <originalmsg@from.com>');
  expect(mimeMsgReplyStr).contains('References: <originalmsg@from.com>');
  t.pass();
});

test('composeEmail format:plain with attachment', async t => {
  const content = 'hello\nwrld';
  const req = {
    format: 'plain', text: content, to: ['some@to.com'], cc: ['some@cc.com'], bcc: [],
    from: 'some@from.com', subject: 'a subj',
    atts: [{ name: 'sometext.txt', type: 'text/plain', base64: Buffer.from('hello, world!!!').toString('base64') }]
  };
  const { data: plainMimeMsg, json: composeEmailJson } = await endpoints.composeEmail(req);
  expectEmptyJson(composeEmailJson as JsonDict);
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

test('parseDecryptMsg unescaped special characters in text (originally text/plain)', async t => {
  const mime = `MIME-Version: 1.0
Date: Fri, 6 Sep 2019 10:48:25 +0000
Message-ID: <some@mail.gmail.com>
Subject: plain text with special chars
From: Human at FlowCrypt <human@flowcrypt.com>
To: FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>
Content-Type: text/plain; charset="UTF-8"

${textSpecialChars}`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [Buffer.from(mime, 'utf8')]);
  expect(decryptJson).deep.equal({
    text: textSpecialChars, replyType: 'plain',
    subject: 'plain text with special chars'
  });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: htmlSpecialChars }]);
  t.pass();
});

test('parseDecryptMsg unescaped special characters in text (originally text/html)', async t => {
  const mime = `MIME-Version: 1.0
Date: Fri, 6 Sep 2019 10:48:25 +0000
Message-ID: <some@mail.gmail.com>
Subject: plain text with special chars
From: Human at FlowCrypt <human@flowcrypt.com>
To: FlowCrypt Compatibility <flowcrypt.compatibility@gmail.com>
Content-Type: text/html; charset="UTF-8"

${htmlSpecialChars}`;
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [Buffer.from(mime, 'utf8')]);
  expect(decryptJson).deep.equal({
    text: textSpecialChars, replyType: 'plain',
    subject: 'plain text with special chars'
  });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent: htmlSpecialChars }]);
  t.pass();
});

test('parseDecryptMsg unescaped special characters in encrypted pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: false },
      [await getCompatAsset('direct-encrypted-pgpmime-special-chars')]);
  expect(decryptJson).deep.equal({
    text: textSpecialChars, replyType: 'encrypted',
    subject: 'direct encrypted pgpmime special chars'
  });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: htmlSpecialChars }]);
  t.pass();
});

test('parseDecryptMsg unescaped special characters in encrypted text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: false },
      [await getCompatAsset('direct-encrypted-text-special-chars')]);
  expect(decryptJson).deep.equal({ text: textSpecialChars, replyType: 'encrypted' });
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent: htmlSpecialChars }]);
  t.pass();
});

test('parseDecryptMsg - plain inline img', async t => {
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

<div dir="ltr"><div>Below</div><div><div><img src="cid:ii_jz5exwmh0" alt="image.png" width="16" height="16">
<br></div></div><div>Above<br></div></div>

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
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [Buffer.from(mime, 'utf8')]);
  expect(decryptJson).deep.equal({
    text: 'Below\n[image: image.png]\nAbove',
    replyType: 'plain', subject: 'tiny inline img plain'
  });
  expectData(blocks, 'msgBlocks', [{
    rendered: true, frameColor: 'plain',
    htmlContent: '<div><div>Below</div><div><div><img src="data:image/png;base64,' +
      'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/' +
      '9hAAAABHNCSVQICAgIfAhkiAAAAMFJREFUOE' +
      '+lU9sRg0AIZDNpym9rSAumJm0hNfidsgic5w1wGJ1kZ3zgwvI4AQtIAHrq4zKY5uJ715sGP7C44BdP' +
      'nZj1gaRVERBPpYJfUSpoGLeyir2Glg64mxMQg9f6xQbU94zrBDBWgVCBBmecbyGWbcrLgpX+OkR+L4ShPw3bdtdCnMmZfSig2a' +
      '+gtcD1R0LyA1mh6OdmsJNnmW0Sfwp75LYevQ5AsUI3g0aKI+llEe3KQbcx28SsnZi9LNO/6/wBmhVJ7HDmOd4AAAAASUVORK5C' +
      'YII=" alt="image.png" />\n<br /></div></div><div>Above<br /></div></div>'
  }]);
  t.pass();
});

test('parseDecryptMsg - signed message preserve newlines', async t => {
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
  const { data: blocks, json: decryptJson } = await endpoints.parseDecryptMsg(
    { keys, isMime: false }, [Buffer.from(mime, 'utf8')]
  );
  expect(decryptJson).deep.equal({
    text: 'Standard message\n\nsigned inline\n\n' +
      'should easily verify\nThis is email footer', replyType: 'plain'
  });
  expectData(blocks, 'msgBlocks', [{
    rendered: true, frameColor: 'gray',
    htmlContent: 'Standard message<br /><br />signed inline<br />' +
      '<br />should easily verify<br />This is email footer'
  }]);
  t.pass();
});

test('composeEmail format:encryptInline -> parseDecryptMsg', async t => {
  const content = 'hello\nwrld';
  const { pubKeys, keys } = getKeypairs('rsa1');
  const req = {
    pubKeys, format: 'encryptInline', text: content,
    to: ['encrypted@to.com'], cc: [], bcc: [], from: 'encr@from.com', subject: 'encr subj'
  };
  const { data: encryptedMimeMsg, json: encryptJson } = await endpoints.composeEmail(req);
  expectEmptyJson(encryptJson as JsonDict);
  const encryptedMimeStr = encryptedMimeMsg.toString();
  expect(encryptedMimeStr).contains('To: encrypted@to.com');
  expect(encryptedMimeStr).contains('MIME-Version: 1.0');
  expectData(encryptedMimeMsg, 'armoredMsg'); // armored msg block should be contained in the mime message
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [encryptedMimeMsg]);
  expect(decryptJson).deep.equal({ text: content, replyType: 'encrypted', subject: 'encr subj' });
  expectData(blocks, 'msgBlocks',
    [{ rendered: true, frameColor: 'green', htmlContent: content.replace(/\n/g, '<br />') }]);
  t.pass();
});

test('composeEmail format:encryptInline with attachment', async t => {
  const content = 'hello\nwrld';
  const { pubKeys } = getKeypairs('rsa1');
  const req = {
    pubKeys, format: 'encryptInline', text: content, to: ['encrypted@to.com'], cc: [], bcc: [],
    from: 'encr@from.com',
    subject: 'encr subj',
    atts: [{
      name: 'topsecret.txt', type: 'text/plain',
      base64: Buffer.from('hello, world!!!').toString('base64')
    }]
  };
  const { data: encryptedMimeMsg, json: encryptJson } = await endpoints.composeEmail(req);
  expectEmptyJson(encryptJson as JsonDict);
  const encryptedMimeStr = encryptedMimeMsg.toString();
  expect(encryptedMimeStr).contains('To: encrypted@to.com');
  expect(encryptedMimeStr).contains('MIME-Version: 1.0');
  expect(encryptedMimeStr).contains('topsecret.txt.pgp');
  // armored msg block should be contained in the mime message
  expectData(encryptedMimeMsg, 'armoredMsg');
  t.pass();
});

for (const keypairName of allKeypairNames.filter(name => name !== 'expired' && name !== 'revoked')) {
  test(`encryptFile -> decryptFile ${keypairName}`, async t => {
    const { pubKeys, keys } = getKeypairs(keypairName);
    const name = 'myfile.txt';
    const content = Buffer.from([10, 20, 40, 80, 160, 0, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
    const { data: encryptedFile, json: encryptJson } =
      await endpoints.encryptFile({ pubKeys, name }, [content]);
    expectEmptyJson(encryptJson as JsonDict);
    expectData(encryptedFile);
    const { data: decryptedContent, json: decryptJson } =
      await endpoints.decryptFile({ keys }, [encryptedFile]);
    expect(decryptJson).to.deep.equal({ decryptSuccess: { name } });
    expectData(decryptedContent, 'binary', content);
    t.pass();
  });
}

test('gmailBackupSearch', async t => {
  const { data, json } = await endpoints.gmailBackupSearch({ acctEmail: 'test@acct.com' });
  expect(json).to.deep.equal({
    query: 'from:test@acct.com to:test@acct.com (subject:"Your FlowCrypt Backup" OR subject: ' +
      '"Your CryptUp Backup" OR subject: "All you need to know about CryptUP (contains a backup)"' +
      ' OR subject: "CryptUP Account Backup") -is:spam'
  });
  expectNoData(data);
  t.pass();
});

test('isEmailValid - true', async t => {
  const { data, json } = await endpoints.isEmailValid({ email: 'test@acct.com' });
  expect(json).to.deep.equal({ valid: true });
  expectNoData(data);
  t.pass();
});

test('isEmailValid - false', async t => {
  const { data, json } = await endpoints.isEmailValid({ email: 'testacct.com' });
  expect(json).to.deep.equal({ valid: false });
  expectNoData(data);
  t.pass();
});

test('parseKeys', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('rsa1');
  const { data, json } = await endpoints.parseKeys({}, [Buffer.from(pubkey)]);
  const expected = {
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
          "\n" +
          "xsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\n" +
          "Zln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\n" +
          "mbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\n" +
          "lxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\n" +
          "ct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\n" +
          "niRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\n" +
          "AAHNEFRlc3QgPHRAZXN0LmNvbT7CwHUEEAEIACkFAlwBWOEGCwkHCAMCCRA6\n" +
          "MPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAA1pMH/R9oEVHaTdEzs/jbsfJk\n" +
          "6xm2oQ/G7KewtSqawAC6nou0+GKvgICxvkNK+BivMLylut+MJqh2gHuExdzx\n" +
          "HFNtKH69BzlK7hDBjyyrLuHIxc4YZaxHGe5ny3wF4QkEgfI+C5chH7Bi+jV6\n" +
          "94L40zEeFO2OhIif8Ti9bRb2Pk6UV5MrsdM0K6J0gTQeTaRecQSg07vO3E8/\n" +
          "GwfP2Dnq4yHICF/eaop+9QWj8UstEE6nEs7SSTrjIAxwAeZzpkjkXPXTLjz6\n" +
          "EcS/9EU7B+5v1qwXk1YeW1qerKJn6Qd6hqJ5gkVzq3sy3eODyrEwpNQoAR4J\n" +
          "8e3VQkKOn9oiAlFTglFeBhfOwE0EXAFY4QEH/2dyWbH3y9+hKk9RxwFzO+5n\n" +
          "GaqT6Njoh368GEEWgSG11NKlrD8k2y1/R1Nc3xEIWMHSUe1rnWWVONKhupwX\n" +
          "ABTnj8coM5beoxVu9p1oYgum4IwLF0yAtaWll1hjsECm/U33Ok36JDa0iu+d\n" +
          "RDfXbEo5cX9bzc1QnWdM5tBg2mxRkssbY3eTPXUe4FLcT0WAQ5hjLW0tPneG\n" +
          "zlu2q9DkmngjDlwGgGhMCa/508wMpgGugE/C4V41EiiTAtOtVzGtdqPGVdoZ\n" +
          "eaYZLc9nTQderaDu8oipaWIwsshYWX4uVVvo7xsx5c5PWXRdI70aUs5IwMRz\n" +
          "uljbq+SYCNta/uJRYc0AEQEAAcLAXwQYAQgAEwUCXAFY4QkQOjD0zAqajxAC\n" +
          "GwwAAI03B/9aWF8l1v66Qaw4O8P3VyQn0/PkVWJYVt5KjMW4nexAfM4BlUw6\n" +
          "97rP5IvfYXNh47Cm8VKqxgcXodzJrouzgwiPFxXmJe5Ug24FOpmeSeIl83Uf\n" +
          "CzaiIm+B6K5cf2NuHTrr4pElDaQ7RQGH2m2cMcimv4oWU9a0tRjt1e7XQAfQ\n" +
          "SWoCalUbLBeYORgVAF97MUNqeth6FMT5STjq+AGgnNZ2vdsUnASS/HbQQUUO\n" +
          "aVGVjo29lB6fS+UHT2gV/E/WQInjok5UrUMaFHwpO0VNP057DNyqhZwxaAs5\n" +
          "BsSgJlOC5hrT+PKlfr9ic75fqnJqmLircB+hVnfhGR9OzH3RCIky\n" +
          "=VKq5\n" +
          "-----END PGP PUBLIC KEY BLOCK-----\n",
        "users": [
          "Test <t@est.com>"
        ],
        "ids": [
          {
            "fingerprint": "E76853E128A0D376CAE47C143A30F4CC0A9A8F10", "longid": "3A30F4CC0A9A8F10",
            "shortid": "0A9A8F10", "keywords": "DEMAND MARBLE CREDIT BENEFIT POTTERY CAPITAL"
          },
          {
            "fingerprint": "9EF2F8F36A841C0D5FAB8B0F0BAB9C018B265D22", "longid": "0BAB9C018B265D22",
            "shortid": "8B265D22", "keywords": "ARM FRIEND ABOUT BIND GRAPE CATTLE"
          }
        ],
        "algo": {
          "algorithm": "rsaEncryptSign",
          "bits": 2047,
          "algorithmId": 1
        },
        "created": 1543592161,
        "lastModified": 1543592161,
        "revoked": false
      }
    ]
  };
  expect(json).to.deep.equal(expected);
  expectNoData(data);
  t.pass();
});

test('parseKeys - expiration and date last updated', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('expired');
  const { data, json } = await endpoints.parseKeys({}, [Buffer.from(pubkey)]);
  const expected = {
    "format": "armored",
    "keyDetails": [
      {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
          "\n" +
          "xsBNBF8PcdUBCADi8no6T4Bd9Ny5COpbheBuPWEyDOedT2EVeaPrfutB1D8i\n" +
          "CP6Rf1cUvs/qNUX/O7HQHFpgFuW2uOY4OU5cvcrwmNpOxT3pPt2cavxJMdJo\n" +
          "fwEvloY3OfY7MCqdAj5VUcFGMhubfV810V2n5pf2FFUNTirksT6muhviMymy\n" +
          "uWZLdh0F4WxrXEon7k3y2dZ3mI4xsG+Djttb6hj3gNr8/zNQQnTmVjB0mmpO\n" +
          "FcGUQLTTTYMngvVMkz8/sh38trqkVGuf/M81gkbr1egnfKfGz/4NT3qQLjin\n" +
          "nA8In2cSFS/MipIV14gTfHQAICFIMsWuW/xkaXUqygvAnyFa2nAQdgELABEB\n" +
          "AAHNKDxhdXRvLnJlZnJlc2guZXhwaXJlZC5rZXlAcmVjaXBpZW50LmNvbT7C\n" +
          "wJMEEAEIACYFAl8PcdUFCQAAAAEGCwkHCAMCBBUICgIEFgIBAAIZAQIbAwIe\n" +
          "AQAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJIvQIALG8TGMN\n" +
          "YB4CRouMJawNCLui6Fx4Ba1ipPTaqlJPybLoe6z/WVZwAA9CmbjkCIk683pp\n" +
          "mGQ3GXv7f8Sdk7DqhEhfZ7JtAK/Uw2VZqqIryNrrB0WV3EUHsENCOlq0YJod\n" +
          "Lqtkqgl83lCNDIkeoQwq4IyrgC8wsPgF7YMpxxQLONJvChZxSdCDjnfX3kvO\n" +
          "ZsLYFiKnNlX6wyrKAQxWnxxYhglMf0GDDyh0AJ+vOQHJ9m+oeBnA1tJ5AZU5\n" +
          "aQHvRtyWBKkYaEhljhyWr3eu1JjK4mn7/W6Rszveso33987wtIoQ66GpGcX2\n" +
          "mh7y217y/uXz4D3X5PUEBXIbhvAPty71bnTOwE0EXw9x1QEIALdJgAsQ0Jnv\n" +
          "LXwAKoOammWlUQmracK89v1Yc4mFnImtHDHS3pGsbx3DbNGuiz5BhXCdoPDf\n" +
          "gMxlGmJgShy9JAhrhWFXkvsjW/7aO4bM1wU486VPKXb7Av/dcrfHH0ASj4zj\n" +
          "/TYAeubNoxQtxHgyb13LVCW1kh4Oe6s0ac/hKtxogwEvNFY3x+4yfloHH0Ik\n" +
          "9sbLGk0gS03bPABDHMpYk346406f5TuP6UDzb9M90i2cFxbq26svyBzBZ0vY\n" +
          "zfMRuNsm6an0+B/wS6NLYBqsRyxwwCTdrhYS512yBzCHDYJJX0o3OJNe85/0\n" +
          "TqEBO1prgkh3QMfw13/Oxq8PuMsyJpUAEQEAAcLAfAQYAQgADwUCXw9x1QUJ\n" +
          "AAAAAQIbDAAhCRC+46QtmpyKyRYhBG0+CYZ1RO5ify6Sj77jpC2anIrJARgH\n" +
          "/1KV7JBOS2ZEtO95FrLYnIqI45rRpvT1XArpBPrYLuHtDBwgMcmpiMhhKIZC\n" +
          "FlZkR1W88ENdSkr8Nx81nW+f9JWRR6HuSyom7kOfS2Gdbfwo3bgp48DWr7K8\n" +
          "KV/HHGuqLqd8UfPyDpsBGNx0w7tRo+8vqUbhskquLAIahYCbhEIE8zgy0fBV\n" +
          "hXKFe1FjuFUoW29iEm0tZWX0k2PT5r1owEgDe0g/X1AXgSQyfPRFVDwE3QNJ\n" +
          "1np/Rmygq1C+DIW2cohJOc7tO4gbl11XolsfQ+FU+HewYXy8aAEbrTSRfsff\n" +
          "MvK6tgT9BZ3kzjOxT5ou2SdvTa0eUk8k+zv8OnJJfXA=\n" +
          "=LPeQ\n" +
          "-----END PGP PUBLIC KEY BLOCK-----\n",
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
          "algorithm": "rsaEncryptSign",
          "bits": 2048,
          "algorithmId": 1
        },
        "created": 1594847701,
        "expiration": 1594847702,
        "lastModified": 1594847701,
        "revoked": false
      }
    ]
  };
  expect(json).to.deep.equal(expected);
  expectNoData(data);
  t.pass();
});

test.serial('parseKeys - revoked', async t => {
  const { pubKeys: [pubkey] } = getKeypairs('revoked');
  const { data, json } = await endpoints.parseKeys({}, [Buffer.from(pubkey)]);
  const expected = {
    format: "armored",
    keyDetails: [
      {
        public: "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
          "\n" +
          "xjMEYW8BThYJKwYBBAHaRw8BAQdAYtEoS4d+3cwQWXcs3lvMQueypexTYai7\n" +
          "uXQmxqyOoKrCjAQgFgoAHQUCYW8CLBYhBDkxt0E9uy+mDO+Fzl8Vl4kQoXgK\n" +
          "ACEJEF8Vl4kQoXgKFiEEOTG3QT27L6YM74XOXxWXiRCheAqk5AEApn8X3Oe7\n" +
          "EFgdfo5lkgh6ubpmgyRUpfYHkQE2/S6K+T0BAPGs2py515aUVAgiRy7bJuoY\n" +
          "DKKbOPL1Npd0bgenKgMGzRVyZXZvZWtkQGZsb3djcnlwdC5jb23CXgQTFgoA\n" +
          "BgUCYW8BawAKCRBfFZeJEKF4ChD/AP9gdm4riyAzyGhD4P8ZGW3GtREk56sW\n" +
          "RBB3A/+RUX+qbAEA3FWCs2bUl6pmasXP8QAi0/zoruZiShR2Y2mVAM3T1ATN\n" +
          "FXJldm9rZWRAZmxvd2NyeXB0LmNvbcJeBBMWCgAGBQJhbwFrAAoJEF8Vl4kQ\n" +
          "oXgKecoBALdrD8nkptLlT8Dg4cF+3swfY1urlbdEfEvIjN60HRDLAP4w3qeS\n" +
          "zZ+OyuqPFaw7dM2KOu4++WigtbxRpDhpQ9U8BQ==\n" +
          "=bMwq\n" +
          "-----END PGP PUBLIC KEY BLOCK-----\n",
        users: ["revoekd@flowcrypt.com", "revoked@flowcrypt.com"],
        ids: [{
          fingerprint: "3931B7413DBB2FA60CEF85CE5F15978910A1780A", "longid": "5F15978910A1780A",
          shortid: "10A1780A", keywords: "GALLERY PROTECT TIME CANDY BLEAK ACCESS"
        }],
        algo: { algorithm: "eddsa", curve: "ed25519", algorithmId: 22 },
        created: 1634664782,
        lastModified: 1634664811,
        revoked: true
      }
    ]
  };
  expect(json).to.deep.equal(expected);
  expectNoData(data);
  t.pass();
});

test('decryptKey', async t => {
  const { keys: [key] } = getKeypairs('rsa1');
  const { data, json } = await endpoints.decryptKey({ armored: key.private, passphrases: [key.passphrase] });
  const decryptedKey = await readKey({ armoredKey: json.decryptedKey as string });
  /* eslint-disable @typescript-eslint/no-unused-expressions */
  expect(isFullyDecrypted(decryptedKey)).to.be.true;
  expect(isFullyEncrypted(decryptedKey)).to.be.false;
  /* eslint-enable @typescript-eslint/no-unused-expressions */
  expectNoData(data);
  t.pass();
});

test('encryptKey', async t => {
  const passphrase = 'this is some pass phrase';
  const { decrypted: [decryptedKey] } = getKeypairs('rsa1');
  const { data, json } = await endpoints.encryptKey({ armored: decryptedKey, passphrase });
  const encryptedKey = await readKey({ armoredKey: json.encryptedKey as string });
  /* eslint-disable @typescript-eslint/no-unused-expressions */
  expect(isFullyEncrypted(encryptedKey)).to.be.true;
  expect(isFullyDecrypted(encryptedKey)).to.be.false;
  expect(await decryptKey({
    privateKey: (encryptedKey as PrivateKey),
    passphrase
  })).is.not.null;
  expectNoData(data);
  /* eslint-enable @typescript-eslint/no-unused-expressions */
  t.pass();
});

test('decryptKey gpg-dummy', async t => {
  const { keys: [key] } = getKeypairs('gpg-dummy');
  const encryptedKey = await readKey({ armoredKey: key.private });
  /* eslint-disable @typescript-eslint/no-unused-expressions */
  expect(isFullyEncrypted(encryptedKey)).to.be.true;
  expect(isFullyDecrypted(encryptedKey)).to.be.false;
  const { json } = await endpoints.decryptKey({ armored: key.private, passphrases: [key.passphrase] });
  const decryptedKey = await readKey({ armoredKey: (json.decryptedKey as string) });
  expect(isFullyEncrypted(decryptedKey)).to.be.false;
  expect(isFullyDecrypted(decryptedKey)).to.be.true;
  const { json: json2 } = await endpoints.encryptKey(
    { armored: decryptedKey.armor(), passphrase: 'another pass phrase' });
  const reEncryptedKey = await readKey({ armoredKey: (json2.encryptedKey as string) });
  expect(isFullyEncrypted(reEncryptedKey)).to.be.true;
  expect(isFullyDecrypted(reEncryptedKey)).to.be.false;
  const { json: json3 } = await endpoints.decryptKey(
    { armored: reEncryptedKey.armor(), passphrases: ['another pass phrase'] });
  const reDecryptedKey = await readKey({ armoredKey: (json3.decryptedKey as string) });
  expect(isFullyEncrypted(reDecryptedKey)).to.be.false;
  expect(isFullyDecrypted(reDecryptedKey)).to.be.true;
  /* eslint-enable @typescript-eslint/no-unused-expressions */
  t.pass();
});

test('parseDecryptMsg compat direct-encrypted-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys }, [await getCompatAsset('direct-encrypted-text')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted' });
  t.pass();
});

test('parseDecryptMsg compat direct-encrypted-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys }, [await getCompatAsset('direct-encrypted-pgpmime')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'direct encrypted pgpmime' });
  t.pass();
});

test('parseDecryptMsg compat mime-email-plain', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true }, [await getCompatAsset('mime-email-plain')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'plain', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain' });
  t.pass();
});

test('parseDecryptMsg compat mime-email-plain-iso-2201-jp', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-plain-iso-2201-jp')]);
  const msg = 'Dear Tomas,\n    \nWe\'ve sent you a new message about your app, ' +
    'Enterprise FlowCrypt, app Apple ID: 1591462989.    To view or reply to the ' +
    'message, go to Resolution Center in App Store Connect.\n    \nBest regards,\n' +
    '    App Store Review\n';
  expect(decryptJson.text).to.contain(msg);
  expect(decryptJson.subject).to.eq('New Message from App Store Review Regarding Enterprise FlowCrypt');
  expect(decryptJson.replyType).to.eq('plain');
  const html = '<p>Dear Tomas,</p> <p>We\'ve sent you a new message about your app, Enterprise FlowCrypt, ' +
    'app Apple ID: 1591462989. To view or reply to the message, ' +
    'go to <a href=\"https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa' +
    '/ra/ng/app/1591462989/platform/ios/versions/844846907/resolutioncenter\">' +
    'Resolution Center</a> in App Store Connect.</p> <p>Best regards,<br /> App Store Review</p>';
  const blocksObj = JSON.parse(blocks.toString().replace(/\\n/g, '').replace(/\s+/g, ' '));
  expect(blocksObj.type).eq('plainHtml');
  expect(blocksObj.complete).eq(true);
  expect(blocksObj.content).contains(html);
  t.pass();
});

test('parseDecryptMsg compat mime-email-encrypted-inline-text', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-encrypted-inline-text')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline text' });
  t.pass();
});

test('parseDecryptMsg compat mime-email-encrypted-inline-pgpmime', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-encrypted-inline-pgpmime')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrypted inline pgpmime' });
  t.pass();
});

test('zxcvbnStrengthBar', async t => {
  const { data, json } =
    await endpoints.zxcvbnStrengthBar({ guesses: 88946283684265, purpose: 'passphrase' });
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

test('parseDecryptMsg compat mime-email-encrypted-inline-text-2 Mime-TextEncoder', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-encrypted-inline-text-2')]);
  expectData(blocks, 'msgBlocks', [{ rendered: true, frameColor: 'green', htmlContent }]);
  expect(decryptJson).to.deep.equal({ text, replyType: 'encrypted', subject: 'mime email encrytped inline text 2' });
  t.pass();
});

test('parseDecryptMsg - decryptErr wrong key when decrypting content', async t => {
  const { keys } = getKeypairs('rsa2'); // intentional key mismatch
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys },
      [await getCompatAsset('direct-encrypted-text')]);
  expectData(blocks, 'msgBlocks', [{
    "type": "decryptErr",
    "content": "-----BEGIN PGP MESSAGE-----\n" +
      "Version: FlowCrypt [BUILD_REPLACEABLE_VERSION] Gmail Encryption\n" +
      "Comment: Seamlessly send and receive encrypted email\n" +
      "\n" +
      "wcBMAwurnAGLJl0iAQf+I2exIah3XL/zfPozDmVFSLJk4tBFIlIyFfGYcw5W\n" +
      "+ebOL3Gu/+/oCIIlXrdP0FxIVEYnSEaevmB9p0FfXGpcw4Wr8PBnSubCkn2s\n" +
      "+V//k6W1Uu915GmiwCgDkLTCP7vEHvwUglNvgAatDtNdJ3xrf2gjOOFiYQnn\n" +
      "4JSI1msMfL5tmdFCyXm1g4mUe9MdVXfphrXIyvGu1Sufhv+T5FgteDW0c6lM\n" +
      "g7G6jgX4q5xiT8r2LTxKlxHVlQSqvGlnx/yRXwqBs3PAMiS4u5JlKJX4aKVy\n" +
      "FyN+gq++tWZC1XCSFzXfAf0rXcoDZ7nEkxdkKQqXgA6LCsFD79FMCtuenvzU\n" +
      "U9JEAdvmmpGlextZcfCUmGgclQXgowDnjaXy5Uc6Bzmi8AlY/4MFo0Q3bOU4\n" +
      "kNhLCiXTGNJlFDd0HLz8Cy7YXzLWZ94IuGk=\n" +
      "=Bvit\n" +
      "-----END PGP MESSAGE-----",
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

test('decryptFile - decryptErr wrong key when decrypting attachment', async t => {
  const jsonReq = { keys: getKeypairs('rsa2').keys }; // intentional key mismatch
  const { json: decryptJson } =
    await endpoints.decryptFile(jsonReq,
      [await getCompatAsset('direct-encrypted-key-mismatch-file')]);
  expect(decryptJson).to.deep.equal({
    decryptErr: {
      success: false,
      error: {
        type: "key_mismatch",
        message: "Missing appropriate key"
      },
      longids: {
        message: ["305F81A9AED12035"],
        matching: [],
        chosen: [],
        needPassphrase: []
      },
      isEncrypted: true
    }
  });
  t.pass();
});

test('parseDecryptMsg compat mime-email-plain-html', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-plain-html')]);
  expectData(blocks, 'msgBlocks', [{
    frameColor: 'plain',
    htmlContent: '<p>paragraph 1</p><p>paragraph 2 with <b>bold</b></p><p>paragraph 3 with ' +
      '<em style="color:red">red i</em></p>', rendered: true
  }]);
  expect(decryptJson).to.deep.equal({
    text: `paragraph 1\nparagraph 2 with bold\nparagraph 3 with red i`,
    replyType: 'plain', subject: 'mime email plain html'
  });
  t.pass();
});

test('parseDecryptMsg compat mime-email-plain-with-pubkey', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-plain-with-pubkey')]);
  const expected = [
    { rendered: true, frameColor: 'plain', htmlContent },
    {
      "type": "publicKey",
      "content": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
        "\n" +
        "xsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\n" +
        "Zln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\n" +
        "mbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\n" +
        "lxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\n" +
        "ct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\n" +
        "niRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\n" +
        "AAHNEFRlc3QgPHRAZXN0LmNvbT7CwHUEEAEIACkFAlwBWOEGCwkHCAMCCRA6\n" +
        "MPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAA1pMH/R9oEVHaTdEzs/jbsfJk\n" +
        "6xm2oQ/G7KewtSqawAC6nou0+GKvgICxvkNK+BivMLylut+MJqh2gHuExdzx\n" +
        "HFNtKH69BzlK7hDBjyyrLuHIxc4YZaxHGe5ny3wF4QkEgfI+C5chH7Bi+jV6\n" +
        "94L40zEeFO2OhIif8Ti9bRb2Pk6UV5MrsdM0K6J0gTQeTaRecQSg07vO3E8/\n" +
        "GwfP2Dnq4yHICF/eaop+9QWj8UstEE6nEs7SSTrjIAxwAeZzpkjkXPXTLjz6\n" +
        "EcS/9EU7B+5v1qwXk1YeW1qerKJn6Qd6hqJ5gkVzq3sy3eODyrEwpNQoAR4J\n" +
        "8e3VQkKOn9oiAlFTglFeBhfOwE0EXAFY4QEH/2dyWbH3y9+hKk9RxwFzO+5n\n" +
        "GaqT6Njoh368GEEWgSG11NKlrD8k2y1/R1Nc3xEIWMHSUe1rnWWVONKhupwX\n" +
        "ABTnj8coM5beoxVu9p1oYgum4IwLF0yAtaWll1hjsECm/U33Ok36JDa0iu+d\n" +
        "RDfXbEo5cX9bzc1QnWdM5tBg2mxRkssbY3eTPXUe4FLcT0WAQ5hjLW0tPneG\n" +
        "zlu2q9DkmngjDlwGgGhMCa/508wMpgGugE/C4V41EiiTAtOtVzGtdqPGVdoZ\n" +
        "eaYZLc9nTQderaDu8oipaWIwsshYWX4uVVvo7xsx5c5PWXRdI70aUs5IwMRz\n" +
        "uljbq+SYCNta/uJRYc0AEQEAAcLAXwQYAQgAEwUCXAFY4QkQOjD0zAqajxAC\n" +
        "GwwAAI03B/9aWF8l1v66Qaw4O8P3VyQn0/PkVWJYVt5KjMW4nexAfM4BlUw6\n" +
        "97rP5IvfYXNh47Cm8VKqxgcXodzJrouzgwiPFxXmJe5Ug24FOpmeSeIl83Uf\n" +
        "CzaiIm+B6K5cf2NuHTrr4pElDaQ7RQGH2m2cMcimv4oWU9a0tRjt1e7XQAfQ\n" +
        "SWoCalUbLBeYORgVAF97MUNqeth6FMT5STjq+AGgnNZ2vdsUnASS/HbQQUUO\n" +
        "aVGVjo29lB6fS+UHT2gV/E/WQInjok5UrUMaFHwpO0VNP057DNyqhZwxaAs5\n" +
        "BsSgJlOC5hrT+PKlfr9ic75fqnJqmLircB+hVnfhGR9OzH3RCIky\n" +
        "=VKq5\n" +
        "-----END PGP PUBLIC KEY BLOCK-----\n",
      "complete": true,
      "keyDetails": {
        "public": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
          "\n" +
          "xsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\n" +
          "Zln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\n" +
          "mbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\n" +
          "lxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\n" +
          "ct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\n" +
          "niRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\n" +
          "AAHNEFRlc3QgPHRAZXN0LmNvbT7CwHUEEAEIACkFAlwBWOEGCwkHCAMCCRA6\n" +
          "MPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAA1pMH/R9oEVHaTdEzs/jbsfJk\n" +
          "6xm2oQ/G7KewtSqawAC6nou0+GKvgICxvkNK+BivMLylut+MJqh2gHuExdzx\n" +
          "HFNtKH69BzlK7hDBjyyrLuHIxc4YZaxHGe5ny3wF4QkEgfI+C5chH7Bi+jV6\n" +
          "94L40zEeFO2OhIif8Ti9bRb2Pk6UV5MrsdM0K6J0gTQeTaRecQSg07vO3E8/\n" +
          "GwfP2Dnq4yHICF/eaop+9QWj8UstEE6nEs7SSTrjIAxwAeZzpkjkXPXTLjz6\n" +
          "EcS/9EU7B+5v1qwXk1YeW1qerKJn6Qd6hqJ5gkVzq3sy3eODyrEwpNQoAR4J\n" +
          "8e3VQkKOn9oiAlFTglFeBhfOwE0EXAFY4QEH/2dyWbH3y9+hKk9RxwFzO+5n\n" +
          "GaqT6Njoh368GEEWgSG11NKlrD8k2y1/R1Nc3xEIWMHSUe1rnWWVONKhupwX\n" +
          "ABTnj8coM5beoxVu9p1oYgum4IwLF0yAtaWll1hjsECm/U33Ok36JDa0iu+d\n" +
          "RDfXbEo5cX9bzc1QnWdM5tBg2mxRkssbY3eTPXUe4FLcT0WAQ5hjLW0tPneG\n" +
          "zlu2q9DkmngjDlwGgGhMCa/508wMpgGugE/C4V41EiiTAtOtVzGtdqPGVdoZ\n" +
          "eaYZLc9nTQderaDu8oipaWIwsshYWX4uVVvo7xsx5c5PWXRdI70aUs5IwMRz\n" +
          "uljbq+SYCNta/uJRYc0AEQEAAcLAXwQYAQgAEwUCXAFY4QkQOjD0zAqajxAC\n" +
          "GwwAAI03B/9aWF8l1v66Qaw4O8P3VyQn0/PkVWJYVt5KjMW4nexAfM4BlUw6\n" +
          "97rP5IvfYXNh47Cm8VKqxgcXodzJrouzgwiPFxXmJe5Ug24FOpmeSeIl83Uf\n" +
          "CzaiIm+B6K5cf2NuHTrr4pElDaQ7RQGH2m2cMcimv4oWU9a0tRjt1e7XQAfQ\n" +
          "SWoCalUbLBeYORgVAF97MUNqeth6FMT5STjq+AGgnNZ2vdsUnASS/HbQQUUO\n" +
          "aVGVjo29lB6fS+UHT2gV/E/WQInjok5UrUMaFHwpO0VNP057DNyqhZwxaAs5\n" +
          "BsSgJlOC5hrT+PKlfr9ic75fqnJqmLircB+hVnfhGR9OzH3RCIky\n" +
          "=VKq5\n" +
          "-----END PGP PUBLIC KEY BLOCK-----\n",
        "users": ["Test <t@est.com>"],
        "ids": [
          {
            "fingerprint": "E76853E128A0D376CAE47C143A30F4CC0A9A8F10", "longid": "3A30F4CC0A9A8F10",
            "shortid": "0A9A8F10", "keywords": "DEMAND MARBLE CREDIT BENEFIT POTTERY CAPITAL"
          },
          {
            "fingerprint": "9EF2F8F36A841C0D5FAB8B0F0BAB9C018B265D22", "longid": "0BAB9C018B265D22",
            "shortid": "8B265D22", "keywords": "ARM FRIEND ABOUT BIND GRAPE CATTLE"
          }
        ],
        "algo": { "algorithm": "rsaEncryptSign", "bits": 2047, "algorithmId": 1 },
        "created": 1543592161,
        "lastModified": 1543592161,
        "revoked": false
      }
    },
  ];
  expectData(blocks, 'msgBlocks', expected);
  expect(decryptJson).to.deep.equal({ text, replyType: 'plain', subject: 'mime email plain with pubkey' });
  t.pass();
});

test('parseDecryptMsg plainAtt', async t => {
  const { keys } = getKeypairs('rsa1');
  const { data: blocks, json: decryptJson } =
    await endpoints.parseDecryptMsg({ keys, isMime: true },
      [await getCompatAsset('mime-email-plain-with-attachment')]);
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

test('can process dirty html without throwing', async t => {
  const dirtyBuf = await getHtmlAsset('leak');
  const clean = Xss.htmlSanitizeKeepBasicTags(dirtyBuf.toString());
  expect(clean).to.not.contain('background');
  expect(clean).to.not.contain('script');
  expect(clean).to.not.contain('style');
  expect(clean).to.not.contain('src=http');
  expect(clean).to.not.contain('src="http');
  t.pass();
});

test('verify encrypted+signed message by providing it correct public key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = await endpoints.parseDecryptMsg(
    { keys, isMime: true, verificationPubkeys: pubKeys },
    [await getCompatAsset('mime-email-encrypted-inline-text-signed')]);
  expect(decryptJson.replyType).equals('encrypted');
  expect(decryptJson.subject).equals('mime email encrypted inline text signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

test('verify encrypted+signed message by providing it one wrong and one correct', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const allPubKeys = [];
  for (const pubkey of pubKeys2) allPubKeys.push(pubkey);
  for (const pubkey of pubKeys) allPubKeys.push(pubkey);
  const { json: decryptJson, data: decryptData } = await endpoints.parseDecryptMsg(
    { keys, isMime: true, verificationPubkeys: pubKeys },
    [await getCompatAsset('mime-email-encrypted-inline-text-signed')]);
  expect(decryptJson.replyType).equals('encrypted');
  expect(decryptJson.subject).equals('mime email encrypted inline text signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

test('verify encrypted+signed message by providing it only a wrong public key (fail: cannot verify)',
  async t => {
    const { keys } = getKeypairs('rsa1');
    const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
    const { json: decryptJson, data: decryptData } = await endpoints.parseDecryptMsg(
      { keys, isMime: true, verificationPubkeys: pubKeys2 },
      [await getCompatAsset('mime-email-encrypted-inline-text-signed')]);
    expect(decryptJson.replyType).equals('encrypted');
    expect(decryptJson.subject).equals('mime email encrypted inline text signed');
    const parsedDecryptData = JSON.parse(decryptData.toString());
    expect(!!parsedDecryptData.verifyRes).equals(true);
    expect(parsedDecryptData.verifyRes.match).equals(null);
    t.pass();
  });

test('verify plain-text signed message by providing it correct key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } = await endpoints.parseDecryptMsg(
    { keys, isMime: true, verificationPubkeys: pubKeys },
    [await getCompatAsset('mime-email-plain-signed')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

test('verify plain-text signed message by providing it both correct and incorrect keys', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const allPubKeys = [];
  for (const pubkey of pubKeys2) allPubKeys.push(pubkey);
  for (const pubkey of pubKeys) allPubKeys.push(pubkey);
  const { json: decryptJson, data: decryptData } =
    await endpoints.parseDecryptMsg({ keys, isMime: true, verificationPubkeys: pubKeys },
      [await getCompatAsset('mime-email-plain-signed')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});
test('verify plain-text signed message by providing it wrong key (fail: cannot verify)', async t => {
  const { keys } = getKeypairs('rsa1');
  const { pubKeys: pubKeys2 } = getKeypairs('rsa2');
  const { json: decryptJson, data: decryptData } =
    await endpoints.parseDecryptMsg({ keys, isMime: true, verificationPubkeys: pubKeys2 },
      [await getCompatAsset('mime-email-plain-signed')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(null);
  t.pass();
});

// eslint-disable-next-line max-len
test('verify plain-text signed message that you edited after signing. This invalidates the signature. With correct key. (fail: signature mismatch)', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } =
    await endpoints.parseDecryptMsg({ keys, isMime: true, verificationPubkeys: pubKeys },
      [await getCompatAsset('mime-email-plain-signed-edited')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  // eslint-disable-next-line @typescript-eslint/no-unused-expressions
  expect(parsedDecryptData.verifyRes.match).is.null;
  t.pass();
});

test('verify signed message with detached signature by providing it correct key', async t => {
  const { keys, pubKeys } = getKeypairs('rsa1');
  const { json: decryptJson, data: decryptData } =
    await endpoints.parseDecryptMsg({ keys, isMime: true, verificationPubkeys: pubKeys },
      [await getCompatAsset('mime-email-plain-signed-detached')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('mime email plain signed detached');
  const parsedDecryptData = JSON.parse(decryptData.toString());
  expect(!!parsedDecryptData.verifyRes).equals(true);
  expect(parsedDecryptData.verifyRes.match).equals(true);
  t.pass();
});

test('decryptErr for not integrity protected message', async t => {
  const { keys, pubKeys } = getKeypairs('flowcrypt.compatibility');
  const { json: decryptJson, data: decryptData } =
    await endpoints.parseDecryptMsg({ keys, isMime: true, verificationPubkeys: pubKeys },
      [await getCompatAsset('mime-email-not-integrity-protected')]);
  expect(decryptJson.replyType).equals('plain');
  expect(decryptJson.subject).equals('not integrity protected - should show a warning and not decrypt automatically');
  const blocks = decryptData.toString().split('\n').map(block => JSON.parse(block) as MsgBlock);
  expect(blocks[1]?.decryptErr?.error.type).equals('no_mdc');
  t.pass();
});

test('decrypt bad private key', async t => {
  const key = await PgpKey.read(`-----BEGIN PGP PRIVATE KEY BLOCK-----
Comment: Corrupted encrypted RSA private key
Comment: Passphrase is 123

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
=kFcl
-----END PGP PRIVATE KEY BLOCK-----`);
  await t.throwsAsync(() => PgpKey.decrypt(key, '123'), { instanceOf: Error, message: 'Key is invalid' });
  t.pass();
});

test('decrypt bad unencrypted private key', async t => {
  const unencryptedCorruptedRsaKey = `-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: FlowCrypt Email Encryption [BUILD_REPLACEABLE_VERSION]
Comment: Seamlessly send and receive encrypted email

xcLYBGHcWwkBB/9lhOJ0DQdAaHcrKa50W92WvoH5jBZEKsPrNmefmSol74M1
MZ+afc9NvCZmFZZLrjcQ6lCFIFExWEmq5LNMKo7J7gR533MfqQMX1q0SP2z0
4NZqQoFn/SU3oQ9ZsmN/uqWXPZvN54DcMDGdUmJurRaGQB9PN4aJOljfy0bh
kolS62Nm2A3emsfoaCLxPYBx0R1Mb2mQKgBw40J9bY+5G8fob5G9y2RUrpBu
z/PZwPAaacSbBzs1LKIUsZ3iBaT2k3wzbORq8Ex2uJ1PYbky2q/v1aUJ2ctx
vFXGY3mSB1iUluMfL/xlJr1N+ooNEA0NOzUOgff8f+vRHLNzpZskGJ7DABEB
AAEAB/9OHQssMK6YBXPn1n3XD9gBwPLwFa7C+FmQ++yukuz00rQz5oddGr+H
hb8NIS6niDE0bw13QQ2QEOhyrfigJNUqkDZqgSz0CS0Shh1/DKxsDFpnNa6d
SCvyO9jDxohN37BQ3dTR+9rYUGqwRn681dhOdOHxPz5pX/QrW7OQwgPbCYnp
alz6apDw21iOyjdKubPDU19ANQFkvIvayIPuJ28BirO5VU9a3e7dQMuqvFbR
NKtY/VQmpPrdB2o99UsFWzEJVd+dKTl7ip26odsCx4K3PDOzw+GVN9BGfuCN
qoQ66u+1hSzRwf7x9YUPaBkqE8SlFW078Jy0lSizp8S4srNBBADGZch4/zc2
2+ZFej5jaBHxeB7Dq6aKKFbBSK9zYipre4xqFXgmuePEJHirdgO4sk0xAsCg
DbBgA8ByzTjqQhgXucFA1mLtOpi9GIRHZ0tN7XYfoPoAE1tsNR2AaLEFr2ea
6u83zqU2ErhpGI9supgRCyunfhMXxsoXki/qHNHS6wQA0zgB4eAClgoJ6nW8
K4yB1r3cfrGAedPEXP08Ckdds2ooTZXushgEEgcpOfhpQ7kcFl9LsqhKTTbA
Q4V9vXx3nCJ9LmFUNAvXX1Bno+0I/WFPERF0FrD37nCj10mINYjsSZGxr+p3
dalQRUtad/TeZlC/GDGgd5X+tZozfU1TFVED/jVmgROnkaMpHSDSqQm+NhKv
EXqQR0Oo3xHMzsgxKqwKBANVc66vD9uB5mgu+QrHzlRuEigjmTADsUicaGXW
dwDlogKBxEYdHh4ZJFNhTkbCN+uhGwbSwCvDm45JoiZUXnyO7mF93LOzm1A9
8/bE3DbqhsWkdpEooRhSWWinhb/OOCfNEUJvYiA8cnNhQGJvYi5jb20+wsCN
BBABCAAgBQJh3FsLBgsJBwgDAgQVCAoCBBYCAQACGQECGwMCHgEAIQkQprNm
Gnb2B9MWIQSC/Y9kL3SWdehfWSyms2YadvYH07hnB/9b31piilyTIdwRJAwA
eQVMQLBCyyZSPRLw+sUBoCfsfVs3k7J53OOelQzc5VCFSDbIG9TB1GvJ66Ai
EhsriMSAYPbqqGcgDDeH9cliiKO4Sq0LbIGyUdlhWtMuGJ3/qp3Sj4Q0VGOv
VCwmEUsR/GdsUlw3i8uaBdlad1ypUU0KrPYSSXxDJ17j7LB8DaXzuL/cJQeF
sUmzpkoaI292ARzn8kMH6vdnIaVAq6ArS5qOoNVPneFd+gH6NEOnev1eO1+3
lxRg/tMSs3ybW3eDWFtRlA9h5xSWDtJpBL5wODifNkhoL/eGiM5ZRxnbteLE
7ggNbfZk2Sn+USGU+KuaYlAVx8LYBGHcWwkBCACtf7FkxFcpE32qTYnMofxx
ztdAZvcx5LC5sTTLPv4tU+g2cvmvYfbS6GLgYdpT8zfH12xiThmRTGRJYPSS
LYA717dPEBBcRaTHgs7zLkuCthpMRPt0p0eI00n3h4wCvDrUkViyMbwob3X2
v6BiU8CWasVkyDdZNjMqox54OwGz8TCWFzBmuzVMXh23+zsQQevi1t6toFui
l6v6X0n/s491+X7JcwK91ovITMlOl/gZFR6nG56s4kB6XA7E3qDuBct9KIEo
CD5FIbFbTavxeFSGVxxn36VBQo6qadPIeWP0wilAZhw/nViEzWefzK16lYqq
o2xsk/HUJgwwH7RLRXNZABEBAAEAB/wOAEnHxLt27mJ8AZVe/OyDH6rJwPVu
YpLrbVRCGaOH82dAK5+gKmLxirzd+C+XCj/kYetWdJCGI/jM3iTmfgME8UfS
+swjMiCV1CXQxJnl4r21DXUQaSZx8YEc12SyXM/Pkyop+S8CwVnu73BpNvKK
APRMiYbD7YaMCI1fLP3acDiUUUmegkFyrnvU+ErcglgDw3pGX/2nUde5lBoq
mxMgJ+WouflvS/rJTTfY1FlOjAG0Ui2iUldgH3u7bziz+JikK2K+mtH8RVT6
DxFSKbmsw+/YneaW2meJvPhk/Nptpqtnfkw+oDk0gWmap9l8cnJhu9m404Zp
xw4yR6vOtZahBADRtNb8iVNQZqxFp8luUhFkSVCfJb/v3J2/B1fGVcukQlke
v0mnGHks6LBaICd1s+5PYYwJo1IDBESJfPSyAqa8RFoBuFU9m8VGXZrrPtYe
9jk5A+ZTK5Wu3F8n89c7Ygg3+GqTsbejO15r56G784UBUBTrKn/pqelnahQE
LqueKQQA08ymIjsyJJOaj4sTZdHw2iw9PXHEXn7VcD0Vr1zuTx8y2CyL7Rzq
jQBnrZvlp3EavqcvxHMffwPW7oEkdb2/YRXhokapO4qYuu/BbNZzaOiba5Yi
I9V3g24H23mShAiTJL1RVMoKpilSznUwqRNhejTZrfBrdpj8+xAWQpcFcbED
/02k8e28oPos/C4t55nkUbxaq9CTKFxQ0vNLL1bz5KgAgK8MntGHFs+ZvXXZ
9WdX48PeXRGqAc8G1cjE6ZoCLBYF5oDIx8G8ZuwFFISQeJHmgUi3leFYjK/l
sd+ZeEfPTWw4Xk0rQx3RRHKpqzE6HYXzceHRcjvVWtrmzEgiSgXMSVLCwHYE
GAEIAAkFAmHcWwsCGwwAIQkQprNmGnb2B9MWIQSC/Y9kL3SWdehfWSyms2Ya
dvYH05rAB/4mFtBaGmjuiTvpjOVht3Uo3hVBvwjN/fdvwaIINhAVkBSanvtl
n1/jbkGn3OCZQtoQZzDcwqlpky8O6qkltXya5GYlhd/btUOx7L7zt+WOpcFS
hXFZoWMB0ua9VcXjyQWefVrA0y9+AgL1phseJjelfM32rf0XegAedxKxNxOp
FraCqKUj088pjlLZsORJCsLOgugt7y4O9lf7fNiRo3I81LZsqegqdzcvCeK9
16th/tRiES/wUwhdVRvLACSGOVCGwsWs1KMJQeqqxxIxrxg0zv7yk17WIY/s
PBcqDCjq5jgMhU1oyVclRK7jJdmu0Azvwo2lleLAFLdCzHEXWXUz
=//ru
-----END PGP PRIVATE KEY BLOCK-----`;
  const res = await PgpKey.parse(unencryptedCorruptedRsaKey);
  expect(res.error).to.equals('Key is invalid');
  t.pass();
});
