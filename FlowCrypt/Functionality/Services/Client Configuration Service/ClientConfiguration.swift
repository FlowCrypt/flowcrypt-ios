//
//  OrganisationalRule.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

/// Organisational rules, set domain-wide, and delivered from FlowCrypt Backend
/// These either enforce, alter or forbid various behavior to fit customer needs
class ClientConfiguration {

    let raw: RawClientConfiguration

    init(raw: RawClientConfiguration) {
        self.raw = raw
    }

    /// Internal company SKS-like public key server to trust above Attester
    var customSksPubkeyServer: String? {
        raw.customKeyserverUrl
    }

    /// an internal org FlowCrypt Email Key Manager instance, can manage both public and private keys
    /// use this method when using for PRV sync
    var keyManagerUrlForPrivateKeys: String? {
        raw.keyManagerUrl
    }

    /// an internal org FlowCrypt Email Key Manager instance, can manage both public and private keys
    /// use this method when using for PUB sync
    var keyManagerUrlForPublicKeys: String? {
        (raw.flags ?? []).contains(.noKeyManagerPubLookup)
            ? nil
            : raw.keyManagerUrl
    }

    /// use when finding out if EKM is in use, to change functionality without actually neededing the EKM
    var isUsingKeyManager: Bool {
        raw.keyManagerUrl != nil
    }

    /// Check if key manager url set properly
    var isKeyManagerUrlValid: Bool {
        // check for empty string
        guard let urlString = raw.keyManagerUrl, urlString.isNotEmpty else {
            return false
        }
        // check is url can be configured
        return URL(string: urlString) != nil
    }

    var isUsingFes: Bool {
        raw.fesUrl != nil
    }

    /// Enforce a key algo for keygen, eg rsa2048,rsa4096,curve25519
    var enforcedKeygenAlgo: String? {
        raw.enforceKeygenAlgo
    }

    /// Some orgs want to have newly generated keys include self-signatures that expire some time in the future.
    var getEnforcedKeygenExpirationMonths: Int? {
        raw.enforceKeygenExpireMonths
    }

    /// Some orgs expect 100% of their private keys to be imported from elsewhere (and forbid keygen in the extension)
    var canCreateKeys: Bool {
        !(raw.flags ?? []).contains(.noPrivateKeyCreate)
    }

    /// Some orgs want to forbid backing up of public keys (such as inbox or other methods)
    var canBackupKeys: Bool {
        !(raw.flags ?? []).contains(.noPrivateKeyBackup)
    }

    /// (normally, during setup, if a public key is submitted to Attester and there is
    /// a conflicting key already submitted, the issue will be skipped)
    /// Some orgs want to make sure that their public key gets submitted to attester and conflict errors are NOT ignored:
    var mustSubmitAttester: Bool {
        (raw.flags ?? []).contains(.enforceAttesterSubmit)
    }

    /// Normally, during setup, "remember pass phrase" is unchecked
    /// This option will cause "remember pass phrase" option to be checked by default
    /// This behavior is also enabled as a byproduct of PASS_PHRASE_QUIET_AUTOGEN
    var shouldRememberPassphraseByDefault: Bool {
        (raw.flags ?? []).contains(.defaultRememberPassphrase) || mustAutogenPassPhraseQuietly
    }

    /// This is to be used for customers who run their own FlowCrypt Email Key Manager
    /// If a key can be found on FEKM, it will be auto imported
    /// If not, it will be autogenerated and stored there
    var mustAutoImportOrAutogenPrvWithKeyManager: Bool {
        get throws {
            guard let flags = raw.flags else {
                return false
            }

            guard flags.contains(.privateKeyAutoimportOrAutogen) else {
                return false
            }

            if keyManagerUrlForPrivateKeys == nil {
                throw EmailKeyManagerApiError.wrongOrgRule
            }
            return true
        }
    }

    /// When generating keys, user will not be prompted to choose a pass phrase
    /// Instead a pass phrase will be automatically generated, and stored locally
    /// The pass phrase will NOT be displayed to user, and it will never be asked of the user
    /// This creates the smoothest user experience, for organisations that use full-disk-encryption and don't need pass phrase protection
    var mustAutogenPassPhraseQuietly: Bool {
        (raw.flags ?? []).contains(.passphraseQuietAutogen)
    }

    /// The number to be interpreted as amount of seconds a pass phrase session will last.
    /// Default is 4 hours.
    var passphraseSessionLengthInSeconds: Int {
        if let sessionLength = raw.inMemoryPassPhraseSessionLength {
            return max(1, min(sessionLength, Int.max))
        }
        return 4 * 60 * 60
    }

    /// Some orgs prefer to forbid publishing public keys publicly
    var canSubmitPubToAttester: Bool {
        !(raw.flags ?? []).contains(.noAttesterSubmit)
    }

    /// Some orgs have a list of email domains where they do NOT want such emails to be looked up on public sources (such as Attester)
    /// This is because they already have other means to obtain public keys for these domains, such as from their own internal keyserver
    func canLookupThisRecipientOnAttester(recipient: String) throws -> Bool {
        guard let recipientDomain = recipient.emailParts?.domain else {
            throw AppErr.general("organisational_wrong_email_error".localizeWithArguments(recipient))
        }

        // When allow_attester_search_only_for_domains is set, ignore other flags
        if let allowAttesterSearchOnlyForDomains = raw.allowAttesterSearchOnlyForDomains {
            return allowAttesterSearchOnlyForDomains.contains(recipientDomain)
        }

        let disallowedDomains = raw.disallowAttesterSearchForDomains ?? []

        if disallowedDomains.contains("*") {
            return false
        }

        return !disallowedDomains.contains(recipientDomain)
    }

    /// Some orgs use flows that are only implemented in POST /initial/legacy_submit and not in POST /pub/email@corp.co:
    ///  -> enforcing that submitted keys match customer key server
    /// Until the newer endpoint is ready, this flag will point users in those orgs to the original endpoint
    var useLegacyAttesterSubmit: Bool {
        (raw.flags ?? []).contains(.useLegacyAttesterSubmit)
    }

    /// With this option, sent messages won't have any comment/version in armor, imported keys get imported without armor
    var shouldHideArmorMeta: Bool {
        (raw.flags ?? []).contains(.hideArmorMeta)
    }

    var forbidStoringPassPhrase: Bool {
        (raw.flags ?? []).contains(.forbidStoringPassphrase)
    }

    var keyManagerUrlString: String? {
        raw.keyManagerUrl?.addTrailingSlashIfNeeded
    }

    /**
     * This method checks if the user is set up for using EKM, and if other client configuration is consistent with it.
     * There are three possible outcomes:
     *  1) EKM in use because isUsingKeyManager == true and other client configs are consistent with it (result: no error, use EKM)
     *  2) EKM is in use because isUsingKeyManager == true and other client configs are NOT consistent with it (result: error)
     *  3) EKM is not in use because isUsingKeyManager == false (result: normal login flow)
     */
    func checkUsesEKM() throws -> CheckUsesEKMResult {
        guard isUsingKeyManager else {
            return .doesNotUseEKM
        }
        guard isKeyManagerUrlValid else {
            return .inconsistentClientConfiguration(checkError: .urlNotValid)
        }
        guard try mustAutoImportOrAutogenPrvWithKeyManager else {
            return .inconsistentClientConfiguration(checkError: .autoImportOrAutogenPrvWithKeyManager)
        }
        guard !mustAutogenPassPhraseQuietly else {
            return .inconsistentClientConfiguration(checkError: .autogenPassPhraseQuietly)
        }
        guard !mustSubmitAttester else {
            return .inconsistentClientConfiguration(checkError: .mustSubmitAttester)
        }
        return .usesEKM
    }

    enum CheckUsesEKMResult: Equatable {
        case usesEKM
        case inconsistentClientConfiguration(checkError: InconsistentClientConfigurationError)
        case doesNotUseEKM
    }

    enum InconsistentClientConfigurationError: Error, CustomStringConvertible, Equatable {
        case urlNotValid
        case autoImportOrAutogenPrvWithKeyManager
        case autogenPassPhraseQuietly
        case mustSubmitAttester

        var description: String {
            switch self {
            case .urlNotValid:
                return "organisational_rules_url_not_valid".localized
            case .autoImportOrAutogenPrvWithKeyManager:
                return "organisational_rules_autoimport_or_autogen_with_private_key_manager_error".localized
            case .autogenPassPhraseQuietly:
                return "organisational_rules_autogen_passphrase_quitely_error".localized
            case .mustSubmitAttester:
                return "organisational_rules_must_submit_attester_error".localized
            }
        }
    }
}
