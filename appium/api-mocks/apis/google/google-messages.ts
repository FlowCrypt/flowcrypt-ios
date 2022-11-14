/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

export type GoogleMockAccountEmail = 'e2e.enterprise.test@flowcrypt.com' | 'flowcrypt.compatibility@gmail.com';
export type GoogleMockMessage = 'CC and BCC test' | 'Test 1' | 'Signed and encrypted message' |
  'Honor reply-to address - plain' | 'email with text attachment' | 'test thread rendering' |
  'Message with cc and multiple recipients and text attachment' | 'new message for reply' |
  'Signed only message' | 'Signed only message with detached signature' |
  'Signed only message where the pubkey is not available' | 'Archived thread' |
  'Signed only message that was tempered during transit' | 'Partially signed only message' |
  'encrypted - MDC hash mismatch - modification detected - should fail' |
  'message encrypted for another public key (only one pubkey used)' | 'wrong checksum' |
  'not integrity protected - should show a warning and not decrypt automatically' |
  'key mismatch unexpectedly produces a modal' | 'Test "archive thread" too aggressive' |
  'Test "archive thread" too aggressive new message' | 'Rich text message with attachment' |
  'rich text message with empty body and attachment';
