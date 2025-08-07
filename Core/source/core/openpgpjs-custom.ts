/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import {
  PublicKeyPacket,
  PublicSubkeyPacket,
  SecretKeyPacket,
  SecretSubkeyPacket,
  UserIDPacket,
  UserAttributePacket,
  SignaturePacket,
  KeyID,
  Signature,
} from 'openpgp';

export type OpenPGPDataType = string | Uint8Array;

export type AllowedKeyPackets =
  | PublicKeyPacket
  | PublicSubkeyPacket
  | SecretKeyPacket
  | SecretSubkeyPacket
  | UserIDPacket
  | UserAttributePacket
  | SignaturePacket;

export interface VerificationResult {
  keyID: KeyID;
  verified: Promise<true>; // throws on invalid signature
  signature: Promise<Signature>;
}
