import * as path from 'path';
import * as dotenv from 'dotenv';
dotenv.config();

export const CommonData = {
  account: {
    email: 'e2e.enterprise.test@flowcrypt.com',
    password: process.env.E2E_ENTERPRISE_TESTS_GOOGLE_PASSWORD,
    passPhrase: 'London blueBARREY capi',
    folder: 'Gmail enterprise folder',
    name: 'e2e',
  },
  alias: {
    name: 'FlowCrypt Compatibility',
    email: 'flowcrypt.compatibility@gmail.com',
    subject: 'Check send email as alias',
    message: 'Test message',
  },
  outlookAccount: {
    email: 'e2e.consumer.tests@outlook.com',
    password: process.env.E2E_CONSUMER_TESTS_OUTLOOK_PASSWORD,
    passPhrase: 'flowcrypt compatibility accounts o',
    name: 'e2e.consumer.tests',
    outlookFolder: 'Outlook consumer folder',
  },
  outlookEmail: {
    subject: 'outlook account inbox email',
    message: 'test email from gmail',
    sender: 'e2e.enterprise.test@flowcrypt.com',
  },
  threadMessage: {
    subject: 'test thread rendering',
    sender: 'dmitry@flowcrypt.com',
    senderName: 'Dmitry at FlowCrypt',
    firstThreadMessage: 'first message',
    secondThreadMessage: 'Second thread rendering message',
    thirdThreadMessage: 'Third thread rendering message',
    thirdThreadMessageQuote:
      'On 2022-02-07 at 06:56, e2e.enterprise.test@flowcrypt.com wrote:\n' +
      '> Second thread rendering message\n' +
      '>\n' +
      '> On 04.02.2022 at 11:12 dmitry@flowcrypt.com wrote:\n' +
      '>  > first message',
    firstDate: 'Feb 04, 2022',
    secondDate: 'Feb 07, 2022',
    thirdDate: 'Feb 08, 2022',
  },
  draft: {
    subject1: 'Draft subject',
    subject2: 'Subject for another draft',
    text1: 'Draft text',
    updatedText1: 'Some new text',
    text2: 'Another draft',
  },
  richTextMessage: {
    subject: 'Rich text message with attachment',
    sender: 'flowcrypt.compatibility@gmail.com',
    message:
      'The Rich Text Format (RTF) Specification is a method of encoding formatted text and graphics for easy transfer between applications.',
    attachmentName: 'simple.txt',
    attachmentText: "It's a text attachment",
  },
  richTextMessageWithEmptyBody: {
    subject: 'rich text message with empty body and attachment',
  },
  richTextMessageWithLargeAttachment: {
    subject: 'mime message with large attachment',
  },
  archivedThread: {
    subject: 'Archived thread',
  },
  revokeValidMessage: {
    subject: 'test revoke valid key from ekm',
    message: 'Test revoked key',
  },
  sender: {
    email: 'dmitry@flowcrypt.com',
    name: 'Dmitry at FlowCrypt',
  },
  compatibilitySender: {
    email: 'flowcrypt.compatibility@gmail.com',
    name: 'FlowCrypt Compatibility',
  },
  contact: {
    contactName: 'Dima Flowcrypt',
    email: 'dmitry@flowcrypt.com',
    name: 'Dmitry at FlowCrypt',
  },
  bundleId: {
    id: 'com.flowcrypt.as.ios.debug',
  },
  encryptedEmail: {
    subject: 'encrypted email',
    message: 'test test',
  },
  encryptedEmailWithAttachment: {
    sender: 'flowcrypt.compatibility@gmail.com',
    senderName: 'FlowCrypt Compatibility',
    recipientName: 'Dima FlowCrypt',
    cc: 'Demo User',
    subject: 'Message with cc and multiple recipients and text attachment',
    message: 'This email has cc and multiple recipients and text attachment',
    attachmentName: 'simple.txt',
    encryptedAttachmentName: 'simple.txt.pgp',
  },
  encryptedEmailWithAttachmentWithoutPreview: {
    sender: 'flowcrypt.compatibility@gmail.com',
    subject: 'message with kdbx file',
    attachmentName: 'newDb.kdbx',
  },
  emailWithMultipleRecipientsWithCC: {
    sender: 'ioan@flowcrypt.com',
    senderName: 'Ioan at FlowCrypt',
    recipient: 'robot@flowcrypt.com',
    recipientName: 'FlowCrypt Robot',
    cc: 'robot+cc@flowcrypt.com',
    subject: 'Message with cc and multiple recipients and attachment',
    message: 'This email has cc and multiple recipients and attachment',
    attachmentName: 'image.png',
    encryptedAttachmentName: 'image.png.pgp',
  },
  emailForReplyWithChangingRecipient: {
    senderEmail: 'e2e.enterprise.test@flowcrypt.com',
    recipientName: 'e2e enterprise tests',
    subject: 'new message for reply',
    secondMessage: 'Added new text to this message',
    firstRecipientName: 'Demo key 2',
    secondRecipientName: 'Dmitry at FlowCrypt',
    thirdRecipientName: 'FlowCrypt Robot',
    newRecipientEmail: 'ioan@flowcrypt.com',
    newRecipientName: 'Ioan at FlowCrypt',
  },
  simpleEmail: {
    subject: 'Test 1',
    message: 'Test email',
  },
  longEmail: {
    message: '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nText',
  },
  updateRecipientPublicKey: {
    email: 'updating.key@example.test',
    name: 'Updating key',
    oldSignatureDate: '12 Jan 2022, 07:16:58 PM', // in UTC
    newSignatureDate: '12 Jan 2022, 07:27:20 PM', // in UTC
    oldFingerprints: '7E181662A26EC6748D6FDB1CC7C990C1A2EA78DD, 5C23518345A6595E81EBFEFCA71D94A76202B1D0',
    newFingerprints:
      '7E181662A26EC6748D6FDB1CC7C990C1A2EA78DD, 5C23518345A6595E81EBFEFCA71D94A76202B1D0, 40E4EE0325E38F717737889AC54F277266650211',
  },
  keyMismatchEmail: {
    subject: 'Encrypted message with key mismatch',
    message: 'Could not decrypt:',
  },
  recipientsListEmail: {
    sender: 'flowcrypt.compatibility@gmail.com',
    senderName: 'FlowCrypt Compatibility',
    subject: 'CC and BCC test',
    message: 'Test message for CC and BCC recipients',
    recipients: 'to Robot, robot+cc, e2e.enterprise.test',
    to: 'Robot FlowCrypt robot@flowcrypt.com',
    cc: 'robot+cc@flowcrypt.com',
    bcc: 'e2e.enterprise.test@flowcrypt.com',
  },
  encryptedMDCHashMismatchEmail: {
    senderName: 'FlowCrypt Compatibility',
    subject: 'encrypted - MDC hash mismatch - modification detected - should fail',
    message: 'bad_mdc: Security threat - opening this message is dangerous because it was modified in transit.',
  },
  encryptedForAnotherPublicKeyEmail: {
    subject: 'message encrypted for another public key (only one pubkey used)',
    message: 'key_mismatch: Missing appropriate key',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
    senderName: 'FlowCrypt Compatibility',
  },
  wrongChecksumEmail: {
    subject: 'wrong checksum',
    message: 'format: Error: Ascii armor integrity check failed',
    senderEmail: 'flowcrypt.compatibility@gmail.com',
    senderName: 'FlowCrypt Compatibility',
  },
  notIntegrityProtected: {
    subject: 'not integrity protected - should show a warning and not decrypt automatically',
    message: 'Message is missing integrity checks (MDC). The sender should update their outdated software and resend.',
    senderName: 'FlowCrypt Compatibility',
  },
  keyMismatch: {
    subject: 'key mismatch unexpectedly produces a modal',
    message: 'Here are the images for testing compatibility.',
    senderEmail: 'sunitnandi834@gmail.com',
    senderName: 'Sunit Kumar Nandi',
    encryptedBadgeText: 'encrypted',
    signatureBadgeText: 'not signed',
    firstAttachmentName: 'Screenshot_20180422_125217.png.asc',
    firstAttachmentBody:
      '-----BEGIN PGP MESSAGE-----\r\nVersion: Mailvelope v2.2.0\r\nComment: https://www.mailvelope.com',
  },
  recipientWithoutPublicKey: {
    email: 'no.publickey@flowcrypt.com',
    subject: 'Test subject 1*',
    weakPassword: '123aaBBc',
    password: 'abcABC1*',
    modalMessage: `Set web portal password\nThe recipients will receive a link to read your message on a web portal, where they will need to enter this password.\n\nYou are responsible for sharing this password with recipients (use other medium to share the password - not email)\n\nPassword should include: - one uppercase - one lowercase - one number - one special character eg &/#"-'_%-@,;:!*() - min 8 characters length`,
    plainMessageModal:
      "Message Encryption\n One or more of your recipients don't have encryption set up.\n\nPlease add a message password, or message will be sent unencrypted.",
    emptyPasswordMessage: "Tap to add password for recipients who don't have encryption set up.",
    addedPasswordMessage: 'Web portal password added',
    weakPasswordMessage:
      "Error\nPassword didn't comply with company policy, which requires at least:\n\n- one uppercase - one lowercase - one number - one special character eg &/#\"-'_%-@,;:!*() - 8 characters length\n\nPlease update the password and re-send.",
    passphrasePasswordErrorMessage:
      'Error\nPlease do not use your private key pass phrase as a password for this message.\n\nYou should come up with some other unique password that you can share with recipient.',
    subjectPasswordErrorMessage:
      "Error\nPlease do not include the password in the email subject. Sharing password over email undermines password based encryption.\n\nYou can ask the recipient to also install FlowCrypt, messages between FlowCrypt users don't need a password.",
  },
  honorReplyTo: {
    sender: 'flowcrypt.compatibility@gmail.com',
    replyToEmail: 'reply@domain.com',
    subject: 'Honor reply-to address - plain',
  },
  errors: {
    noPublicKey:
      'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients are missing a public key (marked in gray).\n' +
      '\n' +
      'Please ask them to share it with you, or ask them to also set up FlowCrypt.',
    wrongPassPhrase:
      'Error\n' + 'Could not compose message\n' + '\n' + 'This pass phrase did not match your signing private key.',
    expiredPublicKey:
      'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have expired public keys (marked in orange).\n' +
      '\n' +
      'Please ask them to send you updated public key. If this is an enterprise installation, please ask your systems admin.',
    revokedPublicKey:
      'Error\n' +
      'Could not compose message\n' +
      '\n' +
      'One or more of your recipients have revoked public keys (marked in red).\n' +
      '\n' +
      'Please ask them to send you a new public key. If this is an enterprise installation, please ask your systems admin.',
    wrongPassPhraseOnLogin: 'Error\n' + 'Wrong pass phrase, please try again',
    attachmentDecryptKeyMismatchError:
      'Error decrypting attachment\n' +
      ' Missing appropriate key\n' +
      '\n' +
      'This will likely download a corrupted file. Download anyway?',
    invalidRecipient: 'Invalid recipient\nPlease enter a valid email address.',
    decryptMessageWithNoKeys:
      'Error\n' +
      'Could not open message\n\n' +
      'Your account has no keys. Please check with your Help Desk or IT department.',
  },
  decryptErrorBadge: {
    badgeText: 'decrypt error',
  },
  appPath: {
    old: path.join(process.cwd(), './FlowCryptOld.app'),
    new: path.join(process.cwd(), './FlowCrypt.app'),
  },
  validMockUser: {
    email: 'valid@domain.test',
    name: 'Tom James Holub',
  },
  refreshingKeysFromEkm: {
    wrongPassPhrase: 'Error\nIncorrect pass phrase. Please try again.',
    updatedSuccessfully: 'Account keys updated',
    errorMessage: 'Error\nError updating account keys: ',
  },
  keyManagerURL: {
    mockServer: 'https://127.0.0.1:8001/ekm',
  },
  mockProcessArgs: ['--mock-fes-api', '--mock-attester-api', '--mock-gmail-api'],
};
