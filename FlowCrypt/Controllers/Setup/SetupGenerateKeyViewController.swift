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
import Promises

enum CreateKeyError: Error {
    case weakPassPhrase(_ strength: CoreRes.ZxcvbnStrengthBar)
    // Missing user email
    case missedUserEmail
    // Missing user name
    case missedUserName
    // Pass phrases don't match
    case doesntMatch
    // silent abort
    case conformingPassPhraseError
}

/**
 * Controller which is responsible for generating a new key during setup
 * - User is sent here from **SetupInitialViewController** in case there are no backups found
 * - Here user can enter a pass phrase (can be saved in memory or in encrypted storage) and generate a key
 * - After key is generated, user will be redirected to **main flow** (inbox view)
 */

final class SetupGenerateKeyViewController: SetupCreatePassphraseAbstractViewController {

    private let backupService: BackupServiceType
    private let attester: AttesterApiType

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        user: UserId,
        backupService: BackupServiceType = BackupService(),
        core: Core = .shared,
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator(),
        storage: DataServiceType = DataService.shared,
        keyStorage: KeyStorageType = KeyDataStorage(),
        attester: AttesterApiType = AttesterApi(),
        passPhraseService: PassPhraseServiceType = PassPhraseService()
    ) {
        self.backupService = backupService
        self.attester = attester
        super.init(
            user: user,
            core: core,
            router: router,
            decorator: decorator,
            storage: storage,
            keyStorage: keyStorage,
            passPhraseService: passPhraseService
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
                try await setupAccountWithGeneratedKey(with: passphrase)
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

// MARK: - Setup

extension SetupGenerateKeyViewController {
    private func setupAccountWithGeneratedKey(with passPhrase: String) async throws {
        let userId = try getUserId()

        try awaitPromise(validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))

        let encryptedPrv = try await core.generateKey(passphrase: passPhrase, variant: .curve25519, userIds: [userId])
        try await backupService.backupToInbox(keys: [encryptedPrv.key], for: user)

        keyStorage.addKeys(keyDetails: [encryptedPrv.key],
                           passPhrase: storageMethod == .persistent ? passPhrase: nil,
                           source: .generated,
                           for: user.email)

        if storageMethod == .memory {
            let passPhrase = PassPhrase(value: passPhrase, fingerprints: encryptedPrv.key.fingerprints)
            passPhraseService.savePassPhrase(with: passPhrase, storageMethod: .memory)
        }

        let updateKey = attester.updateKey(
            email: userId.email,
            pubkey: encryptedPrv.key.public,
            token: storage.token
        )

        try awaitPromise(alertAndSkipOnRejection(
            updateKey,
            fail: "Failed to submit Public Key")
        )
        let testWelcome = attester.testWelcome(email: userId.email, pubkey: encryptedPrv.key.public)
        try awaitPromise(alertAndSkipOnRejection(
            testWelcome,
            fail: "Failed to send you welcome email")
        )
    }

    private func getUserId() throws -> UserId {
        guard let email = DataService.shared.email, !email.isEmpty else {
            throw CreateKeyError.missedUserEmail
        }
        guard let name = DataService.shared.email, !name.isEmpty else {
            throw CreateKeyError.missedUserName
        }
        return UserId(email: email, name: name)
    }
}
