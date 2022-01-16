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
    private let service: Service

    init(
        appContext: AppContext,
        user: UserId,
        decorator: SetupViewDecorator = SetupViewDecorator()
    ) {
        self.attester = AttesterApi(
            clientConfiguration: appContext.clientConfigurationService.getSaved(for: user.email)
        )
        self.service = Service(
            appContext: appContext,
            user: user,
            attester: self.attester
        )
        super.init(
            appContext: appContext,
            user: user,
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
                try await service.setupAccount(
                    passPhrase: passphrase,
                    storageMethod: storageMethod,
                    viewController: self
                )
                hideSpinner()
                moveToMainFlow()
            } catch {
                hideSpinner()

                let isErrorHandled = handleCommon(error: error)

                if !isErrorHandled {
                    showAlert(error: error, message: "Could not finish setup, please try again")
                }
            }
        }
    }
}

// TODO temporary solution for background execution problem
private actor Service {
    typealias ViewController = SetupCreatePassphraseAbstractViewController

    private let appContext: AppContext
    private let user: UserId
    private let attester: AttesterApiType

    init(
        appContext: AppContext,
        user: UserId,
        attester: AttesterApiType
    ) {
        self.appContext = appContext
        self.user = user
        self.attester = attester
    }

    func setupAccount(
        passPhrase: String,
        storageMethod: StorageMethod,
        viewController: ViewController
    ) async throws {
        let userId = try getUserId()

        try await viewController.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)

        let encryptedPrv = try await Core.shared.generateKey(
            passphrase: passPhrase,
            variant: .curve25519,
            userIds: [userId]
        )
        
        try await submitKeyToAttester(email: userId.email, publicKey: encryptedPrv.key.public)
        try await appContext.getBackupService().backupToInbox(keys: [encryptedPrv.key], for: user)
        try await putKeypairs(encryptedPrv: encryptedPrv, storageMethod: storageMethod, passPhrase: passPhrase)

        if storageMethod == .memory {
            let passPhrase = PassPhrase(
                value: passPhrase,
                fingerprintsOfAssociatedKey: encryptedPrv.key.fingerprints
            )
            try appContext.passPhraseService.savePassPhrase(with: passPhrase, storageMethod: .memory)
        }

        // sending welcome email is not crucial, so we don't handle errors
        _ = try? await attester.testWelcome(
            email: userId.email,
            pubkey: encryptedPrv.key.public
        )
    }

    @MainActor
    private func putKeypairs(encryptedPrv: CoreRes.GenerateKey, storageMethod: StorageMethod, passPhrase: String) throws {
        try appContext.encryptedStorage.putKeypairs(
            keyDetails: [encryptedPrv.key],
            passPhrase: storageMethod == .persistent ? passPhrase: nil,
            source: .generated,
            for: user.email
        )
    }

    private func submitKeyToAttester(
        email: String,
        publicKey: String
    ) async throws {
        do {
            _ = try await attester.update(
                email: email,
                pubkey: publicKey,
                token: appContext.dataService.token
            )
        } catch {
            throw CreateKeyError.submitKey
        }
    }

    private func getUserId() throws -> UserId {
        guard let email = appContext.dataService.email, !email.isEmpty else {
            throw CreateKeyError.missedUserEmail
        }
        guard let name = appContext.dataService.currentUser?.name, !name.isEmpty else {
            throw CreateKeyError.missedUserName
        }
        return UserId(email: email, name: name)
    }
}
