//
//  EKMService.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/28/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import UIKit

protocol EKMServiceType {
    func refreshKeysFromEKMIfNeeded(in viewController: UIViewController)
}

enum RefreshKeyError: Error {
    case cancelPassPhrase
}

final class EKMService: EKMServiceType {

    let appContext: AppContextWithUser
    var askedUserPassPhrase = false
    let keyMethods: KeyMethodsType

    init(appContext: AppContextWithUser) {
        self.appContext = appContext
        self.keyMethods = KeyMethods()
    }

    func refreshKeysFromEKMIfNeeded(in viewController: UIViewController) {
        Task {
            do {
                self.askedUserPassPhrase = false
                let configuration = try await appContext.clientConfigurationService.configuration
                guard configuration.checkUsesEKM() == .usesEKM else {
                    return
                }
                let emailKeyManagerApi = EmailKeyManagerApi(clientConfiguration: configuration)
                let idToken = try await IdTokenUtils.getIdToken(userEmail: appContext.user.email)
                let keyDetails = try await emailKeyManagerApi.getPrivateKeys(idToken: idToken)
                let localKeys = try appContext.encryptedStorage.getKeypairs(by: appContext.user.email)

                var passPhrase = try fetchCurrentPassphrase()
                let keysToUpdate = try findKeysToUpdate(from: keyDetails, localKeys: localKeys)

                if keysToUpdate.isEmpty {
                    return
                }

                for keyDetail in keysToUpdate {
                    passPhrase = try await saveKeyToLocal(
                        in: viewController,
                        context: appContext,
                        keyDetail: keyDetail,
                        passPhrase: passPhrase
                    )
                }
                await viewController.showToast("refresh_key_success".localized)
            } catch {
                if error is ApiError {
                    return
                }
                // Do not display error alert when no keys are returned
                if let ekmError = error as? EmailKeyManagerApiError, ekmError == .noKeys {
                    return
                }
                // Do not display error alert when user cancels pass phrase prompt
                if let refreshError = error as? RefreshKeyError, refreshError == .cancelPassPhrase {
                    return
                }
                await viewController.showAlert(message: "refresh_key_error".localizeWithArguments(error.errorMessage))
            }
        }
    }

    private func fetchCurrentPassphrase() throws -> String? {
        // If this is called when starting the app, then it doesn't make much difference
        // but conceptually it would be better to look pass phrase both in memory and storage
        return try appContext.passPhraseService.getPassPhrases(for: appContext.user.email).first(where: { $0.value.isNotEmpty })?.value
    }

    private func findKeysToUpdate(from keyDetails: [KeyDetails], localKeys: [Keypair]) throws -> [KeyDetails] {
        var keysToUpdate: [KeyDetails] = []
        for keyDetail in keyDetails {
            guard keyDetail.isFullyDecrypted ?? false else { throw EmailKeyManagerApiError.keysAreUnexpectedlyEncrypted }
            guard let keyLastModified = keyDetail.lastModified else {
                throw EmailKeyManagerApiError.keysAreInvalid
            }
            if let savedLocalKey = localKeys.first(where: { $0.primaryFingerprint == keyDetail.primaryFingerprint }) {
                if savedLocalKey.lastModified < keyLastModified {
                    keysToUpdate.append(keyDetail)
                }
            } else {
                keysToUpdate.append(keyDetail)
            }
        }
        return keysToUpdate
    }

    private func saveKeyToLocal(
        in viewController: UIViewController,
        context: AppContextWithUser,
        keyDetail: KeyDetails,
        passPhrase: String?
    ) async throws -> String? {
        var newPassPhrase = passPhrase
        if newPassPhrase == nil {
            if askedUserPassPhrase {
                return nil
            }
            newPassPhrase = try await requestPassPhraseWithModal(in: viewController)
        }
        guard let newPassPhrase = newPassPhrase else {
            return nil
        }

        guard let privateKey = keyDetail.private else {
            throw CreatePassphraseWithExistingKeyError.noPrivateKey
        }
        let encryptedPrv = try await Core.shared.encryptKey(
            armoredPrv: privateKey,
            passphrase: newPassPhrase
        )
        let parsedKey = try await Core.shared.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
        try context.encryptedStorage.putKeypairs(
            keyDetails: parsedKey.keyDetails,
            passPhrase: nil,
            source: .ekm,
            for: context.user.email
        )
        return newPassPhrase
    }

    @MainActor
    private func requestPassPhraseWithModal(in viewController: UIViewController) async throws -> String {
        self.askedUserPassPhrase = true
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = AlertsFactory.makePassPhraseAlert(
                title: "refresh_key_alert_title".localized,
                onCancel: {
                    return continuation.resume(throwing: RefreshKeyError.cancelPassPhrase)
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }
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
        //  let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyService.getPrvKeyInfo(email: appContext.user.email)
        guard allKeys.isNotEmpty else {
            // tom - todo - nonsensical error type choice https://github.com/FlowCrypt/flowcrypt-ios/issues/859
            //   I copied it from another usage, but has to be changed
            throw KeyServiceError.retrieve
        }
        let matchingKeys = try await self.keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        return matchingKeys.isNotEmpty
    }
}
