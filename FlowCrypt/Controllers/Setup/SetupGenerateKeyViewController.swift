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
@MainActor
final class SetupGenerateKeyViewController: SetupCreatePassphraseAbstractViewController {

    private let backupService: BackupServiceType
    private let attester: AttesterApiType
    private let service: Service

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
        self.service = Service(
            user: user,
            backupService: backupService,
            core: core,
            keyStorage: keyStorage,
            storage: storage,
            attester: attester,
            passPhraseService: passPhraseService
        )
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

    private let user: UserId
    private let backupService: BackupServiceType
    private let core: Core
    private let keyStorage: KeyStorageType
    private let storage: DataServiceType
    private let attester: AttesterApiType
    private let passPhraseService: PassPhraseServiceType

    init(user: UserId,
         backupService: BackupServiceType,
         core: Core,
         keyStorage: KeyStorageType,
         storage: DataServiceType,
         attester: AttesterApiType,
         passPhraseService: PassPhraseServiceType) {
        self.user = user
        self.backupService = backupService
        self.core = core
        self.keyStorage = keyStorage
        self.storage = storage
        self.attester = attester
        self.passPhraseService = passPhraseService
    }

    func setupAccount(passPhrase: String,
                      storageMethod: StorageMethod,
                      viewController: ViewController) async throws {
        let userId = try getUserId()

        try await viewController.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)

        let encryptedPrv = try await core.generateKey(
            passphrase: passPhrase,
            variant: .curve25519,
            userIds: [userId]
        )
        try await backupService.backupToInbox(keys: [encryptedPrv.key], for: user)

        keyStorage.addKeys(keyDetails: [encryptedPrv.key],
                           passPhrase: storageMethod == .persistent ? passPhrase: nil,
                           source: .generated,
                           for: user.email)

        if storageMethod == .memory {
            let passPhrase = PassPhrase(
                value: passPhrase,
                fingerprintsOfAssociatedKey: encryptedPrv.key.fingerprints
            )
            passPhraseService.savePassPhrase(with: passPhrase, storageMethod: .memory)
        }

        await updateKeyAndWelcome(
            email: userId.email,
            publicKey: encryptedPrv.key.public,
            viewController: viewController
        )
    }

    private func updateKeyAndWelcome(
        email: String,
        publicKey: String,
        viewController: ViewController
    ) async {
        do {
            _ = try await attester.updateKey(
                email: email,
                pubkey: publicKey,
                token: storage.token
            )

            await self.testWelcome(
                email: email,
                publicKey: publicKey,
                viewController: viewController
            )
        } catch {
            let message = "Failed to submit Public Key"
            await viewController.showAlert(error: error, message: message) { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.testWelcome(
                        email: email,
                        publicKey: publicKey,
                        viewController: viewController
                    )
                }
            }
        }
    }

    private func testWelcome(email: String, publicKey: String, viewController: ViewController) async {
        do {
            _ = try await attester.testWelcome(
                email: email,
                pubkey: publicKey
            )
        } catch {
            let message = "Failed to send you welcome email"
            await viewController.showAlert(error: error, message: message)
        }
    }

    private func getUserId() throws -> UserId {
        guard let email = storage.email, !email.isEmpty else {
            throw CreateKeyError.missedUserEmail
        }
        guard let name = storage.email, !name.isEmpty else {
            throw CreateKeyError.missedUserName
        }
        return UserId(email: email, name: name)
    }
}
