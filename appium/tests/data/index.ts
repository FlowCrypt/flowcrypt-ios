export const CommonData = {
  account: {
    email: 'e2e.enterprise.test@flowcrypt.com',
    password: process.env.ACCOUNT_PASSWORD,
    passPhrase: 'London blueBARREY capi'
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
    attachmentName: 'image.png'
  },
  simpleEmail: {
    subject: 'Test 1',
    message: 'Test email',
  },
  longEmail: {
    message: '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nText'
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
    message: '',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
    encryptionBadgeText: 'not encrypted',
    signatureBadgeText: 'not signed'
  },
  recipientWithoutPublicKey: {
    email: 'no.publickey@flowcrypt.com'
  },
  recipientWithExpiredPublicKey: {
    email: 'expired@flowcrypt.com'
  },
  recipientWithRevokedPublicKey: {
    email: 'revoked@flowcrypt.com'
  },
  errors: {
    noPublicKey: 'Could not compose message\n' +
      '\n' +
      'One or more of your recipients are missing a public key (marked in gray).\n' +
      '\n' +
      'Please ask them to share it with you, or ask them to also set up FlowCrypt.',
    wrongPassPhrase: 'Could not compose message\n' +
      '\n' +
      'This pass phrase did not match your signing private key',
    expiredPublicKey: 'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have expired public keys (marked in orange).\n' +
      '\n' +
      'Please ask them to send you updated public key. If this is an enterprise installation, please ask your systems admin.',
    revokedPublicKey: 'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have revoked public keys (marked in red).\n' +
      '\n' +
      'Please ask them to send you a new public key. If this is an enterprise installation, please ask your systems admin.'
  },
  decryptErrorBadge: {
    badgeText: 'decrypt error'
  }
};
