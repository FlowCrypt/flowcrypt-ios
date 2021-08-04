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

final class SetupGenerateKeyViewController: TableNodeViewController, PassPhraseSaveable {
    enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, saveLocally, saveInMemory, action, subtitle
    }

    private let parts = Parts.allCases
    private let decorator: SetupViewDecorator
    private let core: Core
    private let router: GlobalRouterType
    private let user: UserId
    private let backupService: BackupServiceType
    private let storage: DataServiceType
    private let keyStorage: KeyStorageType
    private let attester: AttesterApiType
    let passPhraseService: PassPhraseServiceType

    var shouldSaveLocally = true {
        didSet {
            handleSelectedPassPhraseOption()
        }
    }

    var passPhraseIndexes: [IndexPath] {
        [Parts.saveLocally, Parts.saveInMemory]
            .map { IndexPath(row: $0.rawValue, section: 0) }
    }

    private var passPhrase: String?

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
        self.user = user
        self.core = core
        self.router = router
        self.decorator = decorator
        self.backupService = backupService
        self.storage = storage
        self.attester = attester
        self.keyStorage = keyStorage
        self.passPhraseService = passPhraseService

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - UI

extension SetupGenerateKeyViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self

        title = decorator.sceneTitle(for: .createKey)
        observeKeyboardNotifications()
    }

    // TODO: - Ticket? - Unify this logic for all controllers
    // swiftlint:disable discarded_notification_center_observer
    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.adjustForKeyboard(height: self.keyboardHeight(from: notification))
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustForKeyboard(height: 0)
        }
    }

    private func adjustForKeyboard(height: CGFloat) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
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

    private func validateAndConfirmNewPassPhraseOrReject(passPhrase: String) -> Promise<Void> {
        Promise { [weak self] in
            guard let self = self else { throw AppErr.nilSelf }

            let strength = try self.core.zxcvbnStrengthBar(passPhrase: passPhrase)

            guard strength.word.pass else {
                throw CreateKeyError.weakPassPhrase(strength)
            }

            let confirmPassPhrase = try awaitPromise(self.awaitUserPassPhraseEntry())

            guard confirmPassPhrase != nil else {
                throw CreateKeyError.conformingPassPhraseError
            }

            guard confirmPassPhrase == passPhrase else {
                throw CreateKeyError.doesntMatch
            }
        }
    }

    private func awaitUserPassPhraseEntry() -> Promise<String?> {
        Promise<String?>(on: .main) { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let alert = UIAlertController(
                title: "Pass Phrase",
                message: "Confirm Pass Phrase",
                preferredStyle: .alert
            )

            alert.addTextField { textField in
                textField.isSecureTextEntry = true
                textField.accessibilityLabel = "textField"
            }

            alert.addAction(UIAlertAction(title: "cancel".localized, style: .default) { _ in
                resolve(nil)
            })

            alert.addAction(UIAlertAction(title: "ok".localized, style: .default) { [weak alert] _ in
                resolve(alert?.textFields?[0].text)
            })

            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension SetupGenerateKeyViewController {
    private func moveToMainFlow() {
        router.proceed()
    }

    private func showChoosingOptions() {
        showToast("Not implemented yet")
    }

    private func handleButtonAction() {
        view.endEditing(true)
        guard let passPhrase = passPhrase, passPhrase.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        logger.logInfo("Setup account with \(passPhrase)")
        setupAccountWithGeneratedKey(with: passPhrase)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupGenerateKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        parts.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.title(for: .setup),
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.subtitle(for: .choosingPassPhrase),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .passPhrase:
                return TextFieldCellNode(input: .passPhraseTextFieldStyle) { [weak self] action in
                    guard case let .didEndEditing(value) = action else { return }
                    self?.passPhrase = value
                }
                .onShouldReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    self?.handleButtonAction()
                    return true
                }
                .then {
                    $0.becomeFirstResponder()
                }
            case .action:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .setPassPhrase),
                    insets: self.decorator.insets.buttonInsets
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleButtonAction()
                }
            case .subtitle:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.passPhraseLostDescription,
                        insets: .side(8),
                        backgroundColor: .backgroundColor
                    )
                )
            case .divider:
                return DividerCellNode(inset: self.decorator.insets.dividerInsets)
            case .saveLocally:
                return self.saveLocallyNode
            case .saveInMemory:
                return self.saveInMemoryNode
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let part = Parts(rawValue: indexPath.row) else { return }

        switch part {
        case .description:
            showChoosingOptions()
        case .saveLocally:
            shouldSaveLocally = true
        case .saveInMemory:
            shouldSaveLocally = false
        default:
            break
        }
    }
}
