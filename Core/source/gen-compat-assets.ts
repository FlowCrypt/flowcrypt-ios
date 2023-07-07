/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';

// nodejs-mobile expects it as global, but this test runs as standard Nodejs
// global.openpgp = require('openpgp'); // remove it and you'll see what I mean

import * as ava from 'ava';

import { AvaContext, getKeypairs, writeFile } from './test/test-utils';
import { PgpMsg } from './core/pgp-msg';
import { Xss } from './platform/xss';
import { decryptKey, PrivateKey, readKey } from 'openpgp';

const text = Buffer.from('some\n汉\ntxt');
const textSpecialChars = Buffer.from('> special <tag> & other\n> second line');

const pubkeys = [
  '-----BEGIN PGP PUBLIC KEY BLOCK-----\n' +
    'Version: FlowCrypt 6.3.5 Gmail Encryption\n' +
    'Comment: Seamlessly send and receive encrypted email\n' +
    '\n' +
    'xsBNBFwBWOEBB/9uIqBYIPDQbBqHMvGXhgnm+b2i5rNLXrrGoalrp7wYQ654\n' +
    'Zln/+ffxzttRLRiwRQAOG0z78aMDXAHRfI9d3GaRKTkhTqVY+C02E8NxgB3+\n' +
    'mbSsF0Ui+oh1//LT1ic6ZnISCA7Q2h2U/DSAPNxDZUMu9kjh9TjkKlR81fiA\n' +
    'lxuD05ivRxCnmZnzqZtHoUvvCqsENgRjO9a5oWpMwtdItjdRFF7UFKYpfeA+\n' +
    'ct0uUNMRVdPK7MXBEr2FdWiKN1K21dQ1pWiAwj/5cTA8hu5Jue2RcF8FcPfs\n' +
    'niRihQkNqtLDsfY5no1B3xeSnyO2SES1bAHw8ObXZn/C/6jxFztkn4NbABEB\n' +
    'AAHNEFRlc3QgPHRAZXN0LmNvbT7CwHUEEAEIACkFAlwBWOEGCwkHCAMCCRA6\n' +
    'MPTMCpqPEAQVCAoCAxYCAQIZAQIbAwIeAQAA1pMH/R9oEVHaTdEzs/jbsfJk\n' +
    '6xm2oQ/G7KewtSqawAC6nou0+GKvgICxvkNK+BivMLylut+MJqh2gHuExdzx\n' +
    'HFNtKH69BzlK7hDBjyyrLuHIxc4YZaxHGe5ny3wF4QkEgfI+C5chH7Bi+jV6\n' +
    '94L40zEeFO2OhIif8Ti9bRb2Pk6UV5MrsdM0K6J0gTQeTaRecQSg07vO3E8/\n' +
    'GwfP2Dnq4yHICF/eaop+9QWj8UstEE6nEs7SSTrjIAxwAeZzpkjkXPXTLjz6\n' +
    'EcS/9EU7B+5v1qwXk1YeW1qerKJn6Qd6hqJ5gkVzq3sy3eODyrEwpNQoAR4J\n' +
    '8e3VQkKOn9oiAlFTglFeBhfOwE0EXAFY4QEH/2dyWbH3y9+hKk9RxwFzO+5n\n' +
    'GaqT6Njoh368GEEWgSG11NKlrD8k2y1/R1Nc3xEIWMHSUe1rnWWVONKhupwX\n' +
    'ABTnj8coM5beoxVu9p1oYgum4IwLF0yAtaWll1hjsECm/U33Ok36JDa0iu+d\n' +
    'RDfXbEo5cX9bzc1QnWdM5tBg2mxRkssbY3eTPXUe4FLcT0WAQ5hjLW0tPneG\n' +
    'zlu2q9DkmngjDlwGgGhMCa/508wMpgGugE/C4V41EiiTAtOtVzGtdqPGVdoZ\n' +
    'eaYZLc9nTQderaDu8oipaWIwsshYWX4uVVvo7xsx5c5PWXRdI70aUs5IwMRz\n' +
    'uljbq+SYCNta/uJRYc0AEQEAAcLAXwQYAQgAEwUCXAFY4QkQOjD0zAqajxAC\n' +
    'GwwAAI03B/9aWF8l1v66Qaw4O8P3VyQn0/PkVWJYVt5KjMW4nexAfM4BlUw6\n' +
    '97rP5IvfYXNh47Cm8VKqxgcXodzJrouzgwiPFxXmJe5Ug24FOpmeSeIl83Uf\n' +
    'CzaiIm+B6K5cf2NuHTrr4pElDaQ7RQGH2m2cMcimv4oWU9a0tRjt1e7XQAfQ\n' +
    'SWoCalUbLBeYORgVAF97MUNqeth6FMT5STjq+AGgnNZ2vdsUnASS/HbQQUUO\n' +
    'aVGVjo29lB6fS+UHT2gV/E/WQInjok5UrUMaFHwpO0VNP057DNyqhZwxaAs5\n' +
    'BsSgJlOC5hrT+PKlfr9ic75fqnJqmLircB+hVnfhGR9OzH3RCIky\n' +
    '=VKq5\n' +
    '-----END PGP PUBLIC KEY BLOCK-----\n',
];

const subject = (t: AvaContext) => t.title.replace(/\.txt$/, '').replace(/-/g, ' ');

// particular email that tended to cause mimejs-textencoder errors
const textEncoderMimeEmail = (t: AvaContext, text: Buffer | string) =>
  Buffer.from(
    `
Return-Path: <denbond7@denbond7.com>
Delivered-To: default@denbond7.com
Receivefrom mail.denbond7.com (localhost [127.0.0.1])
	by mail.denbond7.com (Postfix) with ESMTP id 35CBC202F1
	for <default@denbond7.com>; Fri, 15 Mar 2019 14:52:10 +0000 (UTC)
X-Virus-ScanneDebian amavisd-new at mail.denbond7.com
Receivefrom mail.denbond7.com ([127.0.0.1])
	by mail.denbond7.com (mail.denbond7.com [127.0.0.1]) (amavisd-new, port 10024)
	with ESMTP id EstQPjUmZ4Hn for <default@denbond7.com>;
	Fri, 15 Mar 2019 14:52:01 +0000 (UTC)
Receivefrom localhost (MiA1 [192.168.3.6])
	by mail.denbond7.com (Postfix) with ESMTP id E17EF202E9
	for <default@denbond7.com>; Fri, 15 Mar 2019 14:52:00 +0000 (UTC)
Content-Type: multipart/mixed;
 boundary="----sinikael-?=_1-15526615192100.5959024994440685"
In-Reply-To: <>
References: <>
To: default@denbond7.com
From: denbond7@denbond7.com
Subject: ${subject(t)}
Date: Fri, 15 Mar 2019 14:51:59 +0000
Message-I<1552661519275-40db11d3-834101fe-9096ab5d@denbond7.com>
MIME-Version: 1.0

------sinikael-?=_1-15526615192100.5959024994440685
Content-Type: text/plain
Content-Transfer-Encoding: quoted-printable

${text.toString()}

------sinikael-?=_1-15526615192100.5959024994440685--
`.replace(/^\n/, ''),
  );

const plainHtmlMimeEmail = (t: AvaContext) =>
  Buffer.from(
    `
Delivered-To: flowcrypt.compatibility@gmail.com
Message-ID: <1760895073.1552049750035.JavaMail.dets@ny-dets-001>
Date: Fri, 8 Mar 2019 07:55:50 -0500 (EST)
From: cryptup.tester@gmail.com
To: flowcrypt.compatibility@gmail.com
Subject: ${subject(t)}
Mime-Version: 1.0
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: quoted-printable

<html><body><p>paragraph 1</p><p>paragraph 2 with <b>bold</b></p><p>par=
agraph 3 with <em style=3D"color:red">red i</em></p></body></html>
`.replace(/^\n/, ''),
  );

const mimeEmail = (t: AvaContext, text: Buffer | string) =>
  Buffer.from(
    `
Delivered-To: flowcrypt.compatibility@gmail.com
Return-Path: <cryptup.tester@gmail.com>
Openpgp: id=6D24791A5B106262B06217C606CA553EC2455D70
From: cryptup.tester@gmail.com
MIME-Version: 1.0
Date: Thu, 2 Nov 2017 17:54:14 -0700
Message-ID: <CANzaQHU9A@mail.gmail.com>
Subject: ${subject(t)}
To: flowcrypt.compatibility@gmail.com
Content-Type: text/plain; charset="UTF-8"

${text.toString()}
`.replace(/^\n/, ''),
  );

// Used to generate encrypted+signed and plaintext signed emails
const mimeEmail2 = (t: AvaContext, text: Buffer | string, original?: Buffer | string) => {
  const orig = original ? original.toString() + '\n\n' : '';
  return Buffer.from(
    `
Delivered-To: flowcrypt.compatibility@gmail.com
Return-Path: <flowcrypt.compatibility@gmail.com>
Openpgp: id=E76853E128A0D376CAE47C143A30F4CC0A9A8F10
From: flowcrypt.compatibility@gmail.com
MIME-Version: 1.0
Date: Thu, 2 Nov 2017 17:54:14 -0700
Message-ID: <CANzaQHU9A@mail.gmail.com>
Subject: ${subject(t)}
To: flowcrypt.compatibility@gmail.com
Content-Type: text/plain; charset="UTF-8"

${orig}${text.toString()}
`.replace(/^\n/, ''),
  );
};

const mimePgp = (t: AvaContext, text: string | Buffer) =>
  Buffer.from(
    `
Content-Type: multipart/mixed; boundary="PpujspXwR9sayhr0t4sBaTxoXX6dlYhLU";
 protected-headers="v1"
From: Henry Electrum <henry.electrum@gmail.com>
To: flowcrypt.compatibility@gmail.com
Message-ID: <3ef6c5d8-e319-09e2-9c86-cda192a083ef@gmail.com>
Subject: ${subject(t)}

--PpujspXwR9sayhr0t4sBaTxoXX6dlYhLU
Content-Type: text/rfc822-headers; protected-headers="v1"
Content-Disposition: inline

From: Henry Electrum <henry.electrum@gmail.com>
To: flowcrypt.compatibility@gmail.com
Subject: ${subject(t)}

--PpujspXwR9sayhr0t4sBaTxoXX6dlYhLU
Content-Type: multipart/alternative;
 boundary="------------F396B399B1F808CB5EF04F7C"
Content-Language: en-US

This is a multi-part message in MIME format.
--------------F396B399B1F808CB5EF04F7C
Content-Type: text/plain; charset=utf-8

${text.toString()}
--------------F396B399B1F808CB5EF04F7C
Content-Type: text/html; charset=utf-8

${Xss.escape(text.toString()).replace(/\n/g, '<br>')}
--------------F396B399B1F808CB5EF04F7C--

--PpujspXwR9sayhr0t4sBaTxoXX6dlYhLU--
`.replace(/^\n/, ''),
  );

const write = async (t: AvaContext, fileContent: Buffer | string) => {
  await writeFile(
    `./source/assets/compat/${t.title}`,
    fileContent instanceof Buffer ? fileContent : Buffer.from(fileContent),
  );
};

ava.default('direct-encrypted-text.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: text, pubkeys, armor: true })) as string;
  await write(t, data);
  t.pass();
});

ava.default('direct-encrypted-pgpmime.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: mimePgp(t, text), pubkeys, armor: true })) as string;
  await write(t, data);
  t.pass();
});

ava.default('direct-encrypted-pgpmime-special-chars.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: mimePgp(t, textSpecialChars), pubkeys, armor: true })) as string;
  await write(t, data);
  t.pass();
});

ava.default('direct-encrypted-text-special-chars.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: textSpecialChars, pubkeys, armor: true })) as string;
  await write(t, data);
  t.pass();
});

ava.default('mime-email-plain.txt', async t => {
  await write(t, mimeEmail(t, text));
  t.pass();
});

ava.default('mime-email-plain-with-pubkey.txt', async t => {
  await write(t, mimeEmail(t, `${text}\n${pubkeys[0]}`));
  t.pass();
});

ava.default('mime-email-encrypted-inline-text.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: text, pubkeys, armor: true })) as string;
  await write(t, mimeEmail(t, data));
  t.pass();
});

ava.default('mime-email-encrypted-inline-pgpmime.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: mimePgp(t, text), pubkeys, armor: true })) as string;
  await write(t, mimeEmail(t, data));
  t.pass();
});

ava.default('mime-email-encrypted-inline-text-2.txt', async t => {
  const data = (await PgpMsg.encrypt({ data: text, pubkeys, armor: true })) as string;
  await write(t, textEncoderMimeEmail(t, data));
  t.pass();
});

ava.default('mime-email-plain-html.txt', async t => {
  await write(t, plainHtmlMimeEmail(t));
  t.pass();
});

ava.default('mime-email-encrypted-inline-text-signed.txt', async t => {
  const { keys } = getKeypairs('rsa1');
  const signingPrv = (await readKey({ armoredKey: keys[0].private })) as PrivateKey;
  // console.log("rsa1 key fingerprint:" + signingPrv.getFingerprint().toUpperCase());
  const signingPrvDecrypted = await decryptKey({ privateKey: signingPrv, passphrase: keys[0].passphrase });
  if (!signingPrvDecrypted) throw Error("Can't decrypt private key");
  const data = (await PgpMsg.encrypt({ data: text, signingPrv: signingPrvDecrypted, pubkeys, armor: true })) as string;
  await write(t, mimeEmail2(t, data));
  t.pass();
});

ava.default('mime-email-plain-signed.txt', async t => {
  const { keys } = getKeypairs('rsa1');
  const signingPrv = (await readKey({ armoredKey: keys[0].private })) as PrivateKey;
  const signingPrvDecrypted = await decryptKey({ privateKey: signingPrv, passphrase: keys[0].passphrase });
  if (!signingPrvDecrypted) throw Error("Can't decrypt private key");
  const data = text.toString();
  const signed = await PgpMsg.sign(signingPrvDecrypted, data);
  await write(t, mimeEmail2(t, signed));
  t.pass();
});
