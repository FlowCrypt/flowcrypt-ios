import * as path from 'path';

export const CommonData = {
  account: {
    email: 'e2e.enterprise.test@flowcrypt.com',
    password: process.env.E2E_ENTERPRISE_TESTS_GOOGLE_PASSWORD,
    passPhrase: 'London blueBARREY capi',
    folder: 'Gmail enterprise folder',
    name: 'e2e'
  },
  outlookAccount: {
    email: 'e2e.consumer.tests@outlook.com',
    password: process.env.E2E_CONSUMER_TESTS_OUTLOOK_PASSWORD,
    passPhrase: 'flowcrypt compatibility accounts o',
    name: 'e2e.consumer.tests',
    outlookFolder: 'Outlook consumer folder'
  },
  outlookEmail: {
    subject: 'outlook account inbox email',
    message: 'test email from gmail',
    sender: 'e2e.enterprise.test@flowcrypt.com'
  },
  sender: {
    email: 'dmitry@flowcrypt.com',
  },
  contact: {
    email: 'dmitry@flowcrypt.com',
    name: 'Dima'
  },
  secondContact: {
    email: 'demo@flowcrypt.com',
    name: 'Demo'
  },
  recipient: {
    email: 'robot@flowcrypt.com',
  },
  bundleId: {
    id: 'com.flowcrypt.as.ios.debug',
  },
  encryptedEmail: {
    subject: 'encrypted email',
    message: 'test test',
  },
  encryptedEmailWithAttachment: {
    subject: 'email with attachment',
    message: 'this email contains attachment',
    attachmentName: 'image.png',
    encryptedAttachmentName: 'image.png.pgp'
  },
  simpleEmail: {
    subject: 'Test 1',
    message: 'Test email',
  },
  longEmail: {
    message: '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nText'
  },
  updateRecipientPublicKey: {
    email: 'updating.key@example.test',
    oldSignatureDate: 'Jan 12, 2022 7:16:58 PM',//in UTC time for remote running
    newSignatureDate:  'Jan 12, 2022 7:27:20 PM',//in UTC time for remote running
    // oldSignatureDate: 'Jan 12, 2022 at 9:16:58 PM', //- for local run
    // newSignatureDate:  'Jan 12, 2022 at 9:27:20 PM', // for local run
    oldFingerprints: '7E181662A26EC6748D6FDB1CC7C990C1A2EA78DD, 5C23518345A6595E81EBFEFCA71D94A76202B1D0',
    newFingerprints: '7E181662A26EC6748D6FDB1CC7C990C1A2EA78DD, 5C23518345A6595E81EBFEFCA71D94A76202B1D0, 40E4EE0325E38F717737889AC54F277266650211'
  },
  keyMismatchEmail: {
    subject: 'Encrypted message with key mismatch',
    message: 'Could not decrypt:',
  },
  recipientsListEmail: {
    sender: 'flowcrypt.compatibility@gmail.com',
    subject: 'CC and BCC test',
    message: 'Test message for CC and BCC recipients',
    recipients: 'to Robot, robot+cc, e2e.enterprise.test',
    to: 'Robot FlowCrypt robot@flowcrypt.com',
    cc: 'robot+cc@flowcrypt.com',
    bcc: 'e2e.enterprise.test@flowcrypt.com'
  },
  encryptedMDCHashMismatchEmail: {
    senderEmail: 'flowcrypt.compatibility@gmail.com',
    subject: 'encrypted - MDC hash mismatch - modification detected - should fail',
    message: 'bad_mdc: Security threat - opening this message is dangerous because it was modified in transit.',
  },
  encryptedForAnotherPublicKeyEmail: {
    subject: 'message encrypted for another public key (only one pubkey used)',
    message: 'key_mismatch: Missing appropriate key',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
  },
  wrongChecksumEmail: {
    subject: 'wrong checksum',
    message: 'format: Error: Ascii armor integrity check on message failed: \'FdCC\' should be \'FddK\'',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
  },
  notIntegrityProtected: {
    subject: 'not integrity protected - should show a warning and not decrypt automatically',
    message: 'Message is missing integrity checks (MDC). The sender should update their outdated software and resend.',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
  },
  keyMismatch: {
    subject: 'key mismatch unexpectedly produces a modal',
    message: 'Here are the images for testing compatibility.',
    senderEmail: 'sunitnandi834@gmail.com',
    encryptedBadgeText: 'encrypted',
    signatureBadgeText: 'not signed',
    firstAttachmentName: 'Screenshot_20180422_125217.png.asc',
    firstAttachmentBody: '-----BEGIN PGP MESSAGE-----\nVersion: Mailvelope v2.2.0\nComment: https://www.mailvelope.com'
  },
  recipientWithoutPublicKey: {
    email: 'no.publickey@flowcrypt.com',
    password: '123456',
    modalMessage: `Set web portal password\nThe recipients will receive a link to read your message on a web portal, where they will need to enter this password.\n\nYou are responsible for sharing this password with recipients (use other medium to share the password - not email)`,
    emptyPasswordMessage: 'Tap to add password for recipients who don\'t have encryption set up.',
    addedPasswordMessage: 'Web portal password added',
  },
  recipientWithExpiredPublicKey: {
    email: 'expired@flowcrypt.com'
  },
  recipientWithRevokedPublicKey: {
    email: 'revoked@flowcrypt.com'
  },
  errors: {
    noPublicKey: 'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients are missing a public key (marked in gray).\n' +
      '\n' +
      'Please ask them to share it with you, or ask them to also set up FlowCrypt.',
    wrongPassPhrase: 'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'This pass phrase did not match your signing private key',
    expiredPublicKey: 'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have expired public keys (marked in orange).\n' +
      '\n' +
      'Please ask them to send you updated public key. If this is an enterprise installation, please ask your systems admin.',
    revokedPublicKey: 'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have revoked public keys (marked in red).\n' +
      '\n' +
      'Please ask them to send you a new public key. If this is an enterprise installation, please ask your systems admin.',
    wrongPassPhraseOnLogin: 'Error\n' +
      'Wrong pass phrase, please try again',
    attachmentDecryptKeyMismatchError: 'Error decrypting attachment\n' +
      ' Missing appropriate key\n' +
      '\n' +
      'This will likely download a corrupted file. Download anyway?'
  },
  decryptErrorBadge: {
    badgeText: 'decrypt error'
  },
  appPath: {
    old: path.join(process.cwd(), './FlowCryptOld.app'),
    new: path.join(process.cwd(), './FlowCrypt.app')
  }
};
