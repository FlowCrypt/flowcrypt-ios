//
//  SetupEKMKeyViewController.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 13.08.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

enum CreatePassphraseWithExistingKeyError: Error {
    // No private key was found
    case noPrivateKey
}

/**
 * Controller which is responsible for setting up a keys received from EKM
 * - User is sent here from **SetupInitialViewController** in case he has keys on EKM
 * - Here user can enter a pass phrase (will be saved in memory)
 * - After passphrase is set up, user will be redirected to **main flow** (inbox view)
 */

final class SetupEKMKeyViewController: SetupCreatePassphraseAbstractViewController {

    override var parts: [SetupCreatePassphraseAbstractViewController.Parts] {
        SetupCreatePassphraseAbstractViewController.Parts.ekmKeysSetup
    }
    private let keys: [KeyDetails]

    init(
        user: UserId,
        keys: [KeyDetails] = [],
        core: Core = .shared,
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator(),
        storage: DataServiceType = DataService.shared,
        keyStorage: KeyStorageType = KeyDataStorage(),
        passPhraseService: PassPhraseServiceType = PassPhraseService()
    ) {
        self.keys = keys
        super.init(
            user: user,
            fetchedKeysCount: keys.count,
            core: core,
            router: router,
            decorator: decorator,
            storage: storage,
            keyStorage: keyStorage,
            passPhraseService: passPhraseService
        )
        self.storageMethod = .memory
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func setupAccount(with passphrase: String) {
        Task {
            do {
                try await setupAccountWithKeysFetchedFromEkm(with: passphrase)
                hideSpinner()
                moveToMainFlow()
            } catch {
                hideSpinner()

                let isErrorHandled = self.handleCommon(error: error)
                if !isErrorHandled {
                    showAlert(error: error, message: "Could not finish setup, please try again")
                }
            }
        }
    }

    override func setupUI() {
        super.setupUI()
        title = decorator.sceneTitle(for: .choosePassPhrase)
    }
}

// MARK: - Setup

extension SetupEKMKeyViewController {

    private func setupAccountWithKeysFetchedFromEkm(with passPhrase: String) async throws {
        self.showSpinner()
        try await self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)
        var allFingerprints: [String] = []
        for keyDetail in self.keys {
            guard let privateKey = keyDetail.private else {
                throw CreatePassphraseWithExistingKeyError.noPrivateKey
            }
            let encryptedPrv = try await self.core.encryptKey(
                armoredPrv: privateKey,
                passphrase: passPhrase
            )
            let parsedKey = try await self.core.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
            self.keyStorage.addKeys(
                keyDetails: parsedKey.keyDetails,
                passPhrase: self.storageMethod == .persistent ? passPhrase : nil,
                source: .ekm,
                for: self.user.email
            )
            allFingerprints.append(contentsOf: parsedKey.keyDetails.flatMap { $0.fingerprints })
        }
        if self.storageMethod == .memory {
            let passPhrase = PassPhrase(value: passPhrase, fingerprintsOfAssociatedKey: allFingerprints.unique())
            self.passPhraseService.savePassPhrase(with: passPhrase, storageMethod: self.storageMethod)
        }
    }
}

extension SetupCreatePassphraseAbstractViewController.Parts {
    static var ekmKeysSetup: [SetupCreatePassphraseAbstractViewController.Parts] {
        return [.title, .description, .passPhrase, .divider, .action, .fetchedKeys]
    }
}
