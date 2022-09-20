//
//  EKMVcHelper.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/28/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol EKMVcHelperType {
    func refreshKeysFromEKMIfNeeded(in viewController: UIViewController)
}

final class EKMVcHelper: EKMVcHelperType {

    private let appContext: AppContextWithUser
    private let keyMethods: KeyMethodsType

    private lazy var alertsFactory = AlertsFactory()

    init(appContext: AppContextWithUser) {
        self.appContext = appContext
        self.keyMethods = KeyMethods()
    }

    func refreshKeysFromEKMIfNeeded(in viewController: UIViewController) {
        Task {
            do {
                let configuration = try await appContext.clientConfigurationService.configuration
                guard try configuration.checkUsesEKM() == .usesEKM else {
                    return
                }
                let passPhraseStorageMethod: PassPhraseStorageMethod = configuration.forbidStoringPassPhrase ? .memory : .persistent
                let emailKeyManagerApi = EmailKeyManagerApi(clientConfiguration: configuration)
                let idToken = try await IdTokenUtils.getIdToken(userEmail: appContext.user.email)
                let fetchedKeys = try await emailKeyManagerApi.getPrivateKeys(idToken: idToken)
                let localKeys = try appContext.encryptedStorage.getKeypairs(by: appContext.user.email)

                try removeLocalKeysIfNeeded(from: fetchedKeys, localKeys: localKeys)

                let keysToUpdate = try findKeysToUpdate(from: fetchedKeys, localKeys: localKeys)
                guard keysToUpdate.isNotEmpty else {
                    return
                }
                guard let passPhrase = try await getPassphrase(in: viewController), passPhrase.isNotEmpty else {
                    return
                }

                for keyDetail in keysToUpdate {
                    try await saveKeyToLocal(
                        context: appContext,
                        keyDetail: keyDetail,
                        passPhrase: passPhrase,
                        passPhraseStorageMethod: passPhraseStorageMethod
                    )
                }

                await viewController.showToast("refresh_key_success".localized)
            } catch {
                // since this is an update function that happens on every startup
                // it's ok if it's skipped sometimes - keys will be updated next time
                if error is ApiError {
                    return
                }
                await viewController.showAlert(
                    message: "refresh_key_error".localizeWithArguments(error.errorMessage)
                )
            }
        }
    }

    private func getPassphrase(in viewController: UIViewController) async throws -> String? {
        // If this is called when starting the app, then it doesn't make much difference
        // but conceptually it would be better to look pass phrase both in memory and storage
        if let passPhrase = try appContext.combinedPassPhraseStorage.getPassPhrases(
            for: appContext.user.email
        ).first(where: { $0.value.isNotEmpty })?.value {
            return passPhrase
        }
        return try await requestPassPhraseWithModal(in: viewController)
    }

    private func findKeysToUpdate(from keyDetails: [KeyDetails], localKeys: [Keypair]) throws -> [KeyDetails] {
        var keysToUpdate: [KeyDetails] = []
        for keyDetail in keyDetails {
            guard keyDetail.isFullyDecrypted ?? false else {
                throw EmailKeyManagerApiError.keysAreUnexpectedlyEncrypted
            }
            guard let keyLastModified = keyDetail.lastModified else {
                throw EmailKeyManagerApiError.keysAreInvalid
            }
            if let savedLocalKey = try localKeys.first(where: { try $0.primaryFingerprint == keyDetail.primaryFingerprint }) {
                // Do not update key if local saved key is revoked one
                if savedLocalKey.lastModified < keyLastModified, !savedLocalKey.isRevoked {
                    keysToUpdate.append(keyDetail)
                }
            } else {
                keysToUpdate.append(keyDetail)
            }
        }
        return keysToUpdate
    }

    private func removeLocalKeysIfNeeded(from serverKeys: [KeyDetails], localKeys: [Keypair]) throws {
        var keypairsToDelete: [Keypair] = []
        for localKey in localKeys {
            // Delete locally saved key if it's removed from server and locally saved key is not revoked key
            if try !serverKeys.contains(where: { try $0.primaryFingerprint == localKey.primaryFingerprint }), !localKey.isRevoked {
                keypairsToDelete.append(localKey)
            }
        }
        try appContext.encryptedStorage.removeKeypairs(keypairs: keypairsToDelete)
    }

    private func saveKeyToLocal(
        context: AppContextWithUser,
        keyDetail: KeyDetails,
        passPhrase: String,
        passPhraseStorageMethod: PassPhraseStorageMethod
    ) async throws {
        guard let privateKey = keyDetail.private else {
            throw CreatePassphraseWithExistingKeyError.noPrivateKey
        }
        let encryptedPrv = try await Core.shared.encryptKey(
            armoredPrv: privateKey,
            passphrase: passPhrase
        )
        let parsedKey = try await Core.shared.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
        try context.encryptedStorage.putKeypairs(
            keyDetails: parsedKey.keyDetails,
            passPhrase: nil,
            source: .ekm,
            for: context.user.email
        )
        let passPhraseObj = PassPhrase(
            value: passPhrase,
            email: appContext.user.email,
            fingerprintsOfAssociatedKey: keyDetail.fingerprints
        )
        try appContext.combinedPassPhraseStorage.savePassPhrase(
            with: passPhraseObj,
            storageMethod: passPhraseStorageMethod
        )
    }

    @MainActor
    private func requestPassPhraseWithModal(in viewController: UIViewController) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = alertsFactory.makePassPhraseAlert(
                title: "refresh_key_alert_title".localized,
                onCancel: {
                    return continuation.resume(returning: "")
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }

                    viewController.presentedViewController?.dismiss(animated: true)

                    Task<Void, Never> {
                        do {
                            let matched = try await self.handlePassPhraseEntry(
                                appContext: self.appContext,
                                passPhrase
                            )
                            if matched {
                                return continuation.resume(returning: passPhrase)
                            }
                            // Pass phrase mismatch, display error alert and ask again
                            try await viewController.showAsyncAlert(message: "refresh_key_invalid_pass_phrase".localized)
                            let newPassPhrase = try await self.requestPassPhraseWithModal(in: viewController)
                            return continuation.resume(returning: newPassPhrase)
                        } catch {
                            return continuation.resume(throwing: error)
                        }
                    }
                }
            )
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    private func handlePassPhraseEntry(
        appContext: AppContextWithUser,
        _ passPhrase: String
    ) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        // let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyAndPassPhraseStorage.getKeypairsWithPassPhrases(email: appContext.user.email)
        guard allKeys.isNotEmpty else {
            throw KeypairError.noAccountKeysAvailable
        }
        let matchingKeys = try await self.keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.combinedPassPhraseStorage.savePassPhrasesInMemory(for: appContext.user.email, passPhrase, privateKeys: matchingKeys)
        return matchingKeys.isNotEmpty
    }
}
