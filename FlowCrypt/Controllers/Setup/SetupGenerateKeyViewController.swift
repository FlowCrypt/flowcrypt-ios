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
    ) throws {
        self.attester = AttesterApi(
            clientConfiguration: try appContext.clientConfigurationService.getSaved(for: appContext.user.email)
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
        storageMethod: StorageMethod
    ) async throws {
        try await validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)

        let encryptedPrv = try await Core.shared.generateKey(
            passphrase: passPhrase,
            variant: .curve25519,
            userIds: [appContext.userId]
        )

        try await submitKeyToAttester(user: appContext.user, publicKey: encryptedPrv.key.public)
        try await appContext.getBackupService().backupToInbox(keys: [encryptedPrv.key], for: appContext.userId)
        try await putKeypairsInEncryptedStorage(encryptedPrv: encryptedPrv, storageMethod: storageMethod, passPhrase: passPhrase)

        if storageMethod == .memory {
            let passPhrase = PassPhrase(
                value: passPhrase,
                fingerprintsOfAssociatedKey: encryptedPrv.key.fingerprints
            )
            try appContext.passPhraseService.savePassPhrase(with: passPhrase, storageMethod: .memory)
        }

        // sending welcome email is not crucial, so we don't handle errors
        _ = try? await attester.testWelcome(
            email: appContext.user.email,
            pubkey: encryptedPrv.key.public
        )
    }

    private func putKeypairsInEncryptedStorage(encryptedPrv: CoreRes.GenerateKey, storageMethod: StorageMethod, passPhrase: String) throws {
        try appContext.encryptedStorage.putKeypairs(
            keyDetails: [encryptedPrv.key],
            passPhrase: storageMethod == .persistent ? passPhrase: nil,
            source: .generated,
            for: appContext.user.email
        )
    }

    // todo - there is a similar method in EnterpriseServierApi
    //   this should be put somewhere general
    private func getIdToken(for user: User) async throws -> String? {
        switch user.authType {
        case .oAuthGmail:
            return try await GoogleUserService(
                currentUserEmail: user.email,
                appDelegateGoogleSessionContainer: nil // needed only when signing in/out
            ).getCachedOrRefreshedIdToken()
        default:
            return Imap(user: user).imapSess?.oAuth2Token
        }
    }

    private func submitKeyToAttester(
        user: User,
        publicKey: String
    ) async throws {
        do {
            _ = try await attester.replace(
                email: user.email,
                pubkey: publicKey,
                idToken: try await getIdToken(for: user)
            )
        } catch {
            throw CreateKeyError.submitKey(error)
        }
    }
}
