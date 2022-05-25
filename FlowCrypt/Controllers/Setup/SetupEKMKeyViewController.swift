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
        appContext: AppContextWithUser,
        keys: [KeyDetails] = [],
        decorator: SetupViewDecorator = SetupViewDecorator()
    ) {
        self.keys = keys
        super.init(
            appContext: appContext,
            fetchedKeysCount: keys.count,
            decorator: decorator
        )
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
                showAlert(message: error.errorMessage)
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
        let clientConfiguration = try await appContext.clientConfigurationService.configuration
        // self.storageMethod is ignored in this setup flow,
        // since there is no user UI related to storage method,
        // so we only follow the client configuration in this flow.
        let storageMethod: PassPhraseStorageMethod = clientConfiguration.forbidStoringPassPhrase ? .memory : .persistent
        try await self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase)
        var allFingerprintsOfAllKeys: [[String]] = []
        for keyDetail in self.keys {
            guard let privateKey = keyDetail.private else {
                throw CreatePassphraseWithExistingKeyError.noPrivateKey
            }
            let encryptedPrv = try await Core.shared.encryptKey(
                armoredPrv: privateKey,
                passphrase: passPhrase
            )
            let parsedKey = try await Core.shared.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
            try appContext.encryptedStorage.putKeypairs(
                keyDetails: parsedKey.keyDetails,
                passPhrase: storageMethod == .persistent ? passPhrase : nil,
                source: .ekm,
                for: self.appContext.user.email
            )
            allFingerprintsOfAllKeys.append(contentsOf: parsedKey.keyDetails.map(\.fingerprints))
        }
        // Save pass phrase in memory when FORBID_STORING_PASS_PHRASE is set
        if storageMethod == .memory {
            for allFingerprintsOfOneKey in allFingerprintsOfAllKeys {
                try appContext.combinedPassPhraseStorage.savePassPhrase(
                    with: PassPhrase(
                        value: passPhrase,
                        email: appContext.user.email,
                        fingerprintsOfAssociatedKey: allFingerprintsOfOneKey
                    ),
                    storageMethod: storageMethod
                )
            }
        }
    }
}

extension SetupCreatePassphraseAbstractViewController.Parts {
    static var ekmKeysSetup: [SetupCreatePassphraseAbstractViewController.Parts] {
        return [.title, .description, .passPhrase, .divider, .action, .fetchedKeys]
    }
}
