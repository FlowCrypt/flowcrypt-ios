//
//  SetupEKMKeyViewController.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 13.08.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Promises

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
    private let keys: [CoreRes.ParseKeys]

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        user: UserId,
        keys: [CoreRes.ParseKeys] = [],
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
            core: core,
            router: router,
            decorator: decorator,
            storage: storage,
            keyStorage: keyStorage,
            passPhraseService: passPhraseService
        )
        self.shouldStorePassPhrase = false
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
        setupAccountWithKeysFetchedFromEkm(with: passphrase)
    }
}

// MARK: - Setup

extension SetupEKMKeyViewController {

    private func setupAccountWithKeysFetchedFromEkm(with passPhrase: String) {
        Promise { [weak self] in
            guard let self = self else { return }
            self.showSpinner()

            try awaitPromise(self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))

            var allFingerprints: [String] = []
            try self.keys.forEach { key in
                try key.keyDetails.forEach { keyDetail in
                    guard let privateKey = keyDetail.private else {
                        throw CreatePassphraseWithExistingKeyError.noPrivateKey
                    }
                    let encryptedPrv = try self.core.encryptKey(
                        armoredPrv: privateKey,
                        passphrase: passPhrase
                    )
                    let parsedKey = try self.core.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
                    self.keyStorage.addKeys(keyDetails: parsedKey.keyDetails, source: .ekm, for: self.user.email)
                    allFingerprints.append(contentsOf: parsedKey.keyDetails.flatMap { $0.fingerprints })
                }
            }
            let passPhrase = PassPhrase(value: passPhrase, fingerprints: allFingerprints.unique())
            self.passPhraseService.savePassPhrase(with: passPhrase, inStorage: self.shouldStorePassPhrase)
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
}

extension SetupCreatePassphraseAbstractViewController.Parts {
    static var ekmKeysSetup: [SetupCreatePassphraseAbstractViewController.Parts] {
        return [.title, .description, .passPhrase, .divider, .action, .subtitle]
    }
}
