/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

import { Dict } from '../core/common';
import { GoogleMockAccountEmail, GoogleMockMessage } from '../apis/google/google-messages';
import { MockUser, MockUserAlias } from 'api-mocks/mock-data';

export type Logger = (line: string) => void;

export type MockConfig = { serverUrl: string };

type Fes$ClientConfiguration$flag =
  | 'NO_PRV_CREATE'
  | 'NO_PRV_BACKUP'
  | 'PRV_AUTOIMPORT_OR_AUTOGEN'
  | 'PASS_PHRASE_QUIET_AUTOGEN'
  | 'ENFORCE_ATTESTER_SUBMIT'
  | 'NO_ATTESTER_SUBMIT'
  | 'USE_LEGACY_ATTESTER_SUBMIT'
  | 'DEFAULT_REMEMBER_PASS_PHRASE'
  | 'HIDE_ARMOR_META'
  | 'FORBID_STORING_PASS_PHRASE'
  | 'DISABLE_FES_ACCESS_TOKEN';

type Fes$ClientConfiguration = {
  flags?: Fes$ClientConfiguration$flag[];
  custom_keyserver_url?: string;
  key_manager_url?: string;
  in_memory_pass_phrase_session_length?: number;
  allow_attester_search_only_for_domains?: string[];
  disallow_attester_search_for_domains?: string[];
  enforce_keygen_algo?: string;
  disallow_password_messages_for_terms?: string[];
  disallow_password_messages_error_text?: string;
  enforce_keygen_expire_months?: number;
};

type FesMessageUploadCheck = {
  to?: string[];
  cc?: string[];
  bcc?: string[];
};

export type FesConfig = {
  returnError?: { code: number; message: string; format?: 'wrong-json' | 'wrong-text' };
  messageUploadCheck?: FesMessageUploadCheck;
  clientConfiguration?: Fes$ClientConfiguration;
};

export type AttesterConfig = {
  enableSubmittingPubkeys?: boolean;
  enableTestWelcome?: boolean;
  servedPubkeys?: Dict<string>;
  returnError?: { code: number; message: string };
};

export type GoogleConfig = {
  accounts: { [email in GoogleMockAccountEmail]?: GoogleMockAccount };
};

export type GoogleMockAccount = {
  aliases?: MockUserAlias[];
  contacts?: MockUser[];
  signature?: string;
  messages?: GoogleMockMessage[];
};

export type WkdConfig = {
  servedPubkeys?: Dict<string>;
  returnError?: { code: number; message: string };
};

export type EkmConfig = {
  returnKeys?: string[];
  returnError?: { code: number; message: string };
};
