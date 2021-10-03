//
//  CreatePrivateKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import Combine
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
    private var cancellable: AnyCancellable?

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
        setupAccountWithGeneratedKey(with: passphrase)
    }
}

// MARK: - Setup

extension SetupGenerateKeyViewController {
    private func setupAccountWithGeneratedKey(with passPhrase: String) {
        showSpinner()

        cancellable = Just(passPhrase)
            .setFailureType(to: Error.self)
            .subscribe(on: DispatchQueue.global())
            .flatMap(validateAndConfirm)
            .flatMap(generateKey)
            .flatMap(backupKey)
            .flatMap(processKey)
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .sinkFuture { [weak self] _ in
                self?.hideSpinner()
                self?.moveToMainFlow()
            } receiveError: { [weak self] error in
                guard let self = self else { return }
                self.hideSpinner()

                let isErrorHandled = self.handleCommon(error: error)

                if !isErrorHandled {
                    self.showAlert(error: error, message: "Could not finish setup, please try again")
                }
            }
    }

    private func validateAndConfirm(_ passPhrase: String) -> Future<GenerateKeyInput, Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            do {
                let userId = try self.getUserId()
                try awaitPromise(self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))
                let input = GenerateKeyInput(passPhrase: passPhrase, userId: userId)
                promise(.success(input))
            } catch {
                promise(.failure(error))
            }
        }
    }

    private func generateKey(_ input: GenerateKeyInput) -> Future<ProcessKeyInput, Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            do {
                let result = try self.core.generateKey(
                    passphrase: input.passPhrase,
                    variant: .curve25519,
                    userIds: [input.userId]
                )
                let input = ProcessKeyInput(
                    passPhrase: input.passPhrase,
                    userId: input.userId,
                    key: result.key
                )
                promise(.success(input))
            } catch {
                promise(.failure(error))
            }
        }
    }

    private func backupKey(_ input: ProcessKeyInput) -> AnyPublisher<ProcessKeyInput, Error> {
        backupService.backupToInbox(keys: [input.key], for: user)
            .map({ _ in input })
            .eraseToAnyPublisher()
    }

    private func processKey(_ input: ProcessKeyInput) -> Future<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            do {
                self.keyStorage.addKeys(
                    keyDetails: [input.key],
                    passPhrase: self.shouldStorePassPhrase ? input.passPhrase: nil,
                    source: .generated,
                    for: self.user.email
                )
                if !self.shouldStorePassPhrase {
                    let passPhrase = PassPhrase(
                        value: input.passPhrase,
                        fingerprints: input.key.fingerprints
                    )
                    self.passPhraseService.savePassPhrase(with: passPhrase, inStorage: false)
                }

                let updateKey: Promise<String> = self.attester.updateKey(
                    email: input.userId.email,
                    pubkey: input.key.public,
                    token: self.storage.token
                )
                try awaitPromise(self.alertAndSkipOnRejection(
                    updateKey,
                    fail: "Failed to submit Public Key")
                )

                let testWelcome: Promise<Void> = self.attester.testWelcome(
                    email: input.userId.email,
                    pubkey: input.key.public
                )
                try awaitPromise(self.alertAndSkipOnRejection(
                    testWelcome,
                    fail: "Failed to send you welcome email")
                )

                promise(.success(()))
            } catch {
                promise(.failure(error))
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

private struct GenerateKeyInput {
    var passPhrase: String
    var userId: UserId
}

private struct ProcessKeyInput {
    var passPhrase: String
    var userId: UserId
    var key: KeyDetails
}
