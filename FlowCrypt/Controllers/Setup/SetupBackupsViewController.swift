//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * Scene which is responsible for recovering user account with backups from inbox and entered pass phrase
 * (typically used for end-users, enterprises tend to either import manually or with EKM)
 * - User is sent here from **SetupInitialViewController** if there was key backups found in inbox
 * - User will be prompted to enter his pass phrase
 * - Pass phrase can be saved in memory for 4 hours or in encrypted local storage
 * - In case entered pass phrase matches with backups, user will be redirected to **main flow** (inbox view)
 */

final class SetupBackupsViewController: TableNodeViewController, PassPhraseSaveable, NavigationChildController {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, saveLocally, saveInMemory, action
    }

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)
    private let appContext: AppContextWithUser
    private let decorator: SetupViewDecorator
    private let keyMethods: KeyMethodsType
    private let fetchedEncryptedKeys: [KeyDetails]

    private var passPhrase: String?

    var storageMethod: PassPhraseStorageMethod = .persistent {
        didSet {
            handleSelectedPassPhraseOption()
        }
    }

    var passPhraseIndexes: [IndexPath] {
        [Parts.saveLocally, Parts.saveInMemory]
            .map { IndexPath(row: $0.rawValue, section: 0) }
    }

    init(
        appContext: AppContextWithUser,
        fetchedEncryptedKeys: [KeyDetails],
        decorator: SetupViewDecorator = SetupViewDecorator(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) {
        self.appContext = appContext
        self.fetchedEncryptedKeys = fetchedEncryptedKeys
        self.decorator = decorator
        self.keyMethods = keyMethods

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        handleBackups()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc override func adjustForKeyboard(notification: Notification) {
        super.adjustForKeyboard(notification: notification)
        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
    }
}

// MARK: - Setup
extension SetupBackupsViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        observeKeyboardNotifications()
    }
}

// MARK: - Actions
extension SetupBackupsViewController {
    private func handleBackups() {
        guard fetchedEncryptedKeys.isNotEmpty else {
            fatalError("Should be handled in SetupInitialViewController")
        }

        node.reloadData()

        node.visibleNodes
            .compactMap { $0 as? TextFieldCellNode }
            .first?
            .becomeFirstResponder()
    }

    private func recoverAccount(with backups: [KeyDetails], and passPhrase: String) async throws {
        logger.logInfo("Start recoverAccount with \(backups.count) keys")
        let matchingKeyBackups = try await keyMethods.filterByPassPhraseMatch(
            keys: backups,
            passPhrase: passPhrase
        ).getUniqueByFingerprintByPreferingLatestLastModified()
        logger.logInfo("matchingKeyBackups = \(matchingKeyBackups.count)")
        guard matchingKeyBackups.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        if storageMethod == .memory {
            for backup in matchingKeyBackups {
                let pp = PassPhrase(
                    value: passPhrase,
                    email: appContext.user.email,
                    fingerprintsOfAssociatedKey: backup.fingerprints
                )
                try appContext.combinedPassPhraseStorage.savePassPhrase(
                    with: pp,
                    storageMethod: storageMethod
                )
            }
        }
        try appContext.encryptedStorage.putKeypairs(
            keyDetails: Array(matchingKeyBackups),
            passPhrase: storageMethod == .persistent ? passPhrase : nil,
            source: .backup,
            for: appContext.user.email
        )
        moveToMainFlow()
    }

    private func handleButtonPressed() {
        view.endEditing(true)

        guard let passPhrase else { return }

        guard passPhrase.isNotEmpty else {
            showPassPhraseErrorAlert()
            return
        }

        showSpinner()

        Task {
            do {
                try await self.recoverAccount(with: self.fetchedEncryptedKeys, and: passPhrase)
            } catch {
                hideSpinner()
                showAlert(
                    error: error,
                    message: "error_setup_failed".localized,
                    onOk: {
                        // todo - what to do? maybe nothing, since they should now see the same button again that they can press again
                    }
                )
            }
        }
    }

    func handleBackButtonTap() {
        Task {
            do {
                try await appContext.globalRouter.signOut(appContext: appContext)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func moveToMainFlow() {
        appContext.globalRouter.proceed()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension SetupBackupsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
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
                        title: self.decorator.subtitle(for: .fetchedKeys(self.fetchedEncryptedKeys.count)),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .passPhrase:
                return TextFieldCellNode(input: .passPhraseTextFieldStyle) { [weak self] action in
                    switch action {
                    case let .didEndEditing(value):
                        self?.passPhrase = value
                    case let .didPaste(textField, value):
                        textField.text = value
                        self?.handleButtonPressed()
                    default:
                        break
                    }
                }
                .then {
                    $0.becomeFirstResponder()
                }
                .onShouldReturn { [weak self] _ in
                    self?.handleButtonPressed()
                    return true
                }
            case .action:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .loadAccount)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleButtonPressed()
                }
                .then {
                    $0.button.accessibilityIdentifier = "aid-load-account-btn"
                }
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
        case .saveLocally:
            storageMethod = .persistent
        case .saveInMemory:
            storageMethod = .memory
        default:
            break
        }
    }
}
