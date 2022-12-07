//
//  CreatePrivateKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * Controller which is responsible for generating a new key during setup
 * - User is sent here from **SetupInitialViewController** in case there are no backups found
 * - Here user can enter a pass phrase (can be saved in memory or in encrypted storage) and generate a key
 * - After key is generated, user will be redirected to **main flow** (inbox view)
 */
final class SetupGenerateKeyViewController: SetupCreatePassphraseAbstractViewController {

    private let attester: AttesterApiType

    init(
        appContext: AppContextWithUser,
        decorator: SetupViewDecorator = SetupViewDecorator()
    ) async throws {
        self.attester = AttesterApi(
            clientConfiguration: try await appContext.clientConfigurationProvider.configuration
        )
        super.init(
            appContext: appContext,
            decorator: decorator
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func setupAccount(with passphrase: String) {
        showSpinner()
        Task {
            do {
                try await setupAccount(
                    passPhrase: passphrase,
                    storageMethod: storageMethod
                )
                hideSpinner()
                moveToMainFlow()
            } catch {
                hideSpinner()
                showAlert(message: error.errorMessage)
            }
        }
    }

    func setupAccount(
        passPhrase: String,
        storageMethod: PassPhraseStorageMethod
    ) async throws {
        try await validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)

        let encryptedPrv = try await Core.shared.generateKey(
            passphrase: passPhrase,
            variant: .curve25519,
            userIds: [appContext.userId]
        )

        try await submitKeyToAttester(user: appContext.user, publicKey: encryptedPrv.key.public)
        try await appContext.getBackupsManager().backupToInbox(keys: [encryptedPrv.key], for: appContext.userId)
        try putKeypairsInEncryptedStorage(encryptedPrv: encryptedPrv, storageMethod: storageMethod, passPhrase: passPhrase)

        if storageMethod == .memory {
            let passPhrase = PassPhrase(
                value: passPhrase,
                email: appContext.user.email,
                fingerprintsOfAssociatedKey: encryptedPrv.key.fingerprints
            )
            try appContext.combinedPassPhraseStorage.savePassPhrase(
                with: passPhrase,
                storageMethod: .memory
            )
        }

        // sending welcome email is not crucial, so we don't handle errors
        guard let idToken = try? await IdTokenUtils.getIdToken(user: appContext.user) else { return }

        try? await attester.testWelcome(
            email: appContext.user.email,
            pubkey: encryptedPrv.key.public,
            idToken: idToken
        )
    }

    private func putKeypairsInEncryptedStorage(
        encryptedPrv: CoreRes.GenerateKey,
        storageMethod: PassPhraseStorageMethod,
        passPhrase: String
    ) throws {
        try appContext.encryptedStorage.putKeypairs(
            keyDetails: [encryptedPrv.key],
            passPhrase: storageMethod == .persistent ? passPhrase : nil,
            source: .generated,
            for: appContext.user.email
        )
    }

    private func submitKeyToAttester(
        user: User,
        publicKey: String
    ) async throws {
        do {
            _ = try await attester.submitPrimaryEmailPubkey(
                email: user.email,
                pubkey: publicKey,
                idToken: try await IdTokenUtils.getIdToken(user: user)
            )
        } catch {
            throw CreateKeyError.submitKey(error)
        }
    }
}
