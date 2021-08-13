//
//  CreatePrivateKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func setupAccount(with passphrase: String) {
        setupAccountWithGeneratedKey(with: passphrase)
    }
}

// MARK: - Setup

extension SetupGenerateKeyViewController {
    private func setupAccountWithGeneratedKey(with passPhrase: String) {
        Promise { [weak self] in
            guard let self = self else { return }
            self.showSpinner()

            let userId = try self.getUserId()

            try awaitPromise(self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))

            let encryptedPrv = try self.core.generateKey(passphrase: passPhrase, variant: .curve25519, userIds: [userId])

            try awaitPromise(self.backupService.backupToInbox(keys: [encryptedPrv.key], for: self.user))

            let passPhrase = PassPhrase(value: passPhrase, fingerprints: encryptedPrv.key.fingerprints)

            self.keyStorage.addKeys(keyDetails: [encryptedPrv.key], source: .generated, for: self.user.email)
            self.passPhraseService.savePassPhrase(with: passPhrase, inStorage: self.shouldSaveLocally)

            let updateKey = self.attester.updateKey(
                email: userId.email,
                pubkey: encryptedPrv.key.public,
                token: self.storage.token
            )

            try awaitPromise(self.alertAndSkipOnRejection(
                updateKey,
                fail: "Failed to submit Public Key")
            )
            let testWelcome = self.attester.testWelcome(email: userId.email, pubkey: encryptedPrv.key.public)
            try awaitPromise(self.alertAndSkipOnRejection(
                testWelcome,
                fail: "Failed to send you welcome email")
            )
        }
        .then(on: .main) { [weak self] in
            self?.hideSpinner()
            self?.moveToMainFlow()
        }
        .catch(on: .main) { [weak self] error in
            guard let self = self else { return }
            self.hideSpinner()

            let isErrorHandled = self.handleCommon(error: error)

            if !isErrorHandled {
                self.showAlert(error: error, message: "Could not finish setup, please try again")
            }
        }
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
