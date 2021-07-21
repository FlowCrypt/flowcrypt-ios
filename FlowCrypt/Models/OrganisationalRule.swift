//
//  OrganisationalRule.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 20.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

/// Organisational rules, set domain-wide, and delivered from FlowCrypt Backend
/// These either enforce, alter or forbid various behavior to fit customer needs
class OrganisationalRules {

    private let clientConfiguration: ClientConfiguration

    init(clientConfiguration: ClientConfiguration) {
        self.clientConfiguration = clientConfiguration
    }

    /// Internal company SKS-like public key server to trust above Attester
    var customSksPubkeyServer: String? {
        clientConfiguration.customKeyserverUrl
    }

    /// an internal org FlowCrypt Email Key Manager instance, can manage both public and private keys
    /// use this method when using for PRV sync
    var keyManagerUrlForPrivateKeys: String? {
        clientConfiguration.keyManagerUrl
    }

    /// an internal org FlowCrypt Email Key Manager instance, can manage both public and private keys
    /// use this method when using for PUB sync
    var keyManagerUrlForPublicKeys: String? {
        (clientConfiguration.flags ?? []).contains(.noKeyManagerPubLookup)
            ? nil
            : clientConfiguration.keyManagerUrl
    }

    /// use when finding out if EKM is in use, to change functionality without actually neededing the EKM
    var isUsingKeyManager: Bool {
        clientConfiguration.keyManagerUrl != nil
    }

    /// Enforce a key algo for keygen, eg rsa2048,rsa4096,curve25519
    var enforcedKeygenAlgo: String? {
        clientConfiguration.enforceKeygenAlgo
    }

    /// Some orgs want to have newly generated keys include self-signatures that expire some time in the future.
    var getEnforcedKeygenExpirationMonths: Int? {
        clientConfiguration.enforceKeygenExpireMonths
    }

    /// Some orgs expect 100% of their private keys to be imported from elsewhere (and forbid keygen in the extension)
    var canCreateKeys: Bool {
        !(clientConfiguration.flags ?? []).contains(.noPrivateKeyCreate)
    }

    /// Some orgs want to forbid backing up of public keys (such as inbox or other methods)
    var canBackupKeys: Bool {
        !(clientConfiguration.flags ?? []).contains(.noPrivateKeyBackup)
    }

    /// (normally, during setup, if a public key is submitted to Attester and there is
    /// a conflicting key already submitted, the issue will be skipped)
    /// Some orgs want to make sure that their public key gets submitted to attester and conflict errors are NOT ignored:
    var mustSubmitAttester: Bool {
        (clientConfiguration.flags ?? []).contains(.enforceAttesterSubmit)
    }

    /// Normally, during setup, "remember pass phrase" is unchecked
    /// This option will cause "remember pass phrase" option to be checked by default
    /// This behavior is also enabled as a byproduct of PASS_PHRASE_QUIET_AUTOGEN
    var shouldRememberPassphraseByDefault: Bool {
        (clientConfiguration.flags ?? []).contains(.defaultRememberPassphrase) || mustAutogenPassPhraseQuietly
    }

    /// This is to be used for customers who run their own FlowCrypt Email Key Manager
    /// If a key can be found on FEKM, it will be auto imported
    /// If not, it will be autogenerated and stored there
    var mustAutoImportOrAutogenPrvWithKeyManager: Bool {
        if !(clientConfiguration.flags ?? []).contains(.privateKeyAutoimportOrAutogen) {
            return false
        }

        if keyManagerUrlForPrivateKeys == nil {
            fatalError("Wrong org rules config: using PRV_AUTOIMPORT_OR_AUTOGEN without key_manager_url")
        }
        return true
    }

    /// When generating keys, user will not be prompted to choose a pass phrase
    /// Instead a pass phrase will be automatically generated, and stored locally
    /// The pass phrase will NOT be displayed to user, and it will never be asked of the user
    /// This creates the smoothest user experience, for organisations that use full-disk-encryption and don't need pass phrase protection
    var mustAutogenPassPhraseQuietly: Bool {
        (clientConfiguration.flags ?? []).contains(.passphraseQuietAutogen)
    }

    /// Some orgs prefer to forbid publishing public keys publicly
    var canSubmitPubToAttester: Bool {
        !(clientConfiguration.flags ?? []).contains(.noAttesterSubmit)
    }

    /// Some orgs have a list of email domains where they do NOT want such emails to be looked up on public sources (such as Attester)
    /// This is because they already have other means to obtain public keys for these domains, such as from their own internal keyserver
    func canLookupThisRecipientOnAttester(recipient email: String) -> Bool {
        !(clientConfiguration.disallowAttesterSearchForDomains ?? []).contains(email.recipientDomain ?? "")
    }

    /// Some orgs use flows that are only implemented in POST /initial/legacy_submit and not in POST /pub/email@corp.co:
    ///  -> enforcing that submitted keys match customer key server
    /// Until the newer endpoint is ready, this flag will point users in those orgs to the original endpoint
    var useLegacyAttesterSubmit: Bool {
        (clientConfiguration.flags ?? []).contains(.useLegacyAttesterSubmit)
    }

    /// With this option, sent messages won't have any comment/version in armor, imported keys get imported without armor
    var shouldHideArmorMeta: Bool {
        (clientConfiguration.flags ?? []).contains(.hideArmorMeta)
    }
}
