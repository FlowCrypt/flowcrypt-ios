//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

// swiftlint:disable line_length
final class SetupViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, action, optionalAction
    }

    private let router: GlobalRouterType
    private let storage: DataServiceType & KeyDataServiceType
    private let decorator: SetupViewDecorator
    private let core: Core
    private let keyMethods: KeyMethodsType
    private let user: UserId

    private var passPhrase: String?
    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    enum SetupError: Error {
        /// fetched keys error
        case emptyFetchedKeys
        /// error while key parsing (associated error for verbose message)
        case parseKey(Error)
        /// no backups found while searching
        case noBackups
    }

    private let fetchedEncryptedKeys: [KeyDetails]

    init(
        fetchedEncryptedKeys: [KeyDetails],
        router: GlobalRouterType = GlobalRouter(),
        storage: DataServiceType & KeyDataServiceType = DataService.shared,
        decorator: SetupViewDecorator = SetupViewDecorator(),
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        user: UserId
    ) {
        if fetchedEncryptedKeys.isEmpty {
            assertionFailure("Should be handled in SetupInitialViewController")
        }
        self.fetchedEncryptedKeys = fetchedEncryptedKeys
        self.router = router
        self.storage = storage
        self.decorator = decorator
        self.core = core
        self.keyMethods = keyMethods
        self.user = user

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processBackupsFetchResult()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

// MARK: - Setup

extension SetupViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        observeKeyboardNotifications()
    }

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

// MARK: - Key processing

extension SetupViewController {
    private func processBackupsFetchResult() {
        node.reloadData()

        node.visibleNodes
            .compactMap { $0 as? TextFieldCellNode }
            .first?
            .becomeFirstResponder()
    }
}

// MARK: - Error Handling

extension SetupViewController {
    private func handleError(with error: SetupError) {
        hideSpinner()
        logger.logWarning("handling error during setup: \(error)")

        switch error {
        case .emptyFetchedKeys:
            let user = DataService.shared.email ?? "unknown_title".localized
            let msg = "setup_no_backups".localized + user
            showSearchBackupError(with: msg)
        case .noBackups:
            showSearchBackupError(with: "setup_no_backups".localized)
        case let .parseKey(error):
            showErrorAlert(with: "setup_action_failed".localized, error: error)
        }
    }

    private func errorAlert(with message: String) -> UIAlertController {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)

        let useOtherAccountAction = UIAlertAction(
            title: "setup_use_otherAccount".localized,
            style: .default
        ) { [weak self] _ in
            self?.handleOtherAccount()
        }

        let retryAction = UIAlertAction(
            title: "Retry",
            style: .default
        ) { [weak self] _ in
            // TODO: - ANTON - rework retry logic - proceed to searching
        }

        alert.addAction(useOtherAccountAction)
        alert.addAction(retryAction)

        return alert
    }

    private func showErrorAlert(with msg: String, error: Error? = nil) {
        hideSpinner()

        let errStr: String = {
            guard let err = error else { return "" }
            return "\n\n\(err)"
        }()

        let alert = errorAlert(with: msg + errStr)

        present(alert, animated: true, completion: nil)
    }

    private func showSearchBackupError(with message: String) {
        let alert = errorAlert(with: message)

        let importAction = UIAlertAction(
            title: "setup_action_import".localized,
            style: .default
        ) { [weak self] _ in
            self?.proceedToKeyImport()
        }

        let createNewPrivateKeyAction = UIAlertAction(
            title: "setup_action_create_new".localized,
            style: .default
        ) { [weak self] _ in
            self?.proceedToCreatingNewKey()
        }

        alert.addAction(importAction)
        alert.addAction(createNewPrivateKeyAction)

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Recover account

extension SetupViewController {
    private func recoverAccount(with backups: [KeyDetails], and passPhrase: String) {

        let matchingKeyBackups = keyMethods.filterByPassPhraseMatch(keys: backups, passPhrase: passPhrase)

        guard matchingKeyBackups.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        storage.addKeys(keyDetails: matchingKeyBackups, passPhrase: passPhrase, source: .backup)

        moveToMainFlow()
    }
}

// MARK: - Navigation

extension SetupViewController {
    private func proceedToKeyImport() {
        hideSpinner()
        // TODO: - ANTON - check proceedToKeyImport
        let viewController = UIViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToCreatingNewKey() {
        hideSpinner()
        let viewController = SetupKeyViewController(user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Events

extension SetupViewController {

    private func handleButtonPressed() {
        view.endEditing(true)
        guard let passPhrase = passPhrase else { return }

        guard passPhrase.isNotEmpty else {
            showAlert(message: "setup_enter_pass_phrase".localized)
            return
        }

        showSpinner()

        // TODO: - fix for spinner
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/291
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.recoverAccount(with: self.fetchedEncryptedKeys, and: passPhrase)
        }
    }

    private func handleOtherAccount() {
        router.signOut()
    }

    private func moveToMainFlow() {
        router.proceed()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.setupTitle,
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        // TODO: - ANTON - check text
                        title: self.decorator.subtitle(for: .choosingPassPhrase),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .passPhrase:
                // TODO: - ANTON - check text
                return TextFieldCellNode(input: .passPhraseTextFieldStyle) { [weak self] action in
                    guard case let .didEndEditing(value) = action else { return }
                    self?.passPhrase = value
                }
                .then {
                    $0.becomeFirstResponder()
                }
                .onShouldReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    self?.handleButtonPressed()
                    return true
                }
            case .action:
                return ButtonCellNode(
                    // TODO: - ANTON - check text
                    title: self.decorator.buttonTitle(for: .loadAccount),
                    insets: self.decorator.insets.buttonInsets
                ) { [weak self] in
                    self?.handleButtonPressed()
                }
                .then {
                    $0.button.accessibilityIdentifier = "load_account"
                }
            case .optionalAction:
                return ButtonCellNode(
                    title: self.decorator.useAnotherAccountTitle,
                    insets: self.decorator.insets.optionalButtonInsets,
                    color: .white
                ) { [weak self] in
                    self?.handleOtherAccount()
                }
            case .divider:
                return DividerCellNode(inset: self.decorator.insets.dividerInsets)
            }
        }
    }
}

// TODO: - ANTON

/*
 During setup
    new key
    when importing key
    when loading from backup
    creating
    entering pass phrase

the user should see two radio buttons:

 o store pass phrase locally -  Default is to store.
 o keep pass phrase in memory

 If the user switches it,
 then we do not store pass phrase with the key (or at all).
 We only keep it in memory for up to 4 hours from the moment it was stored - then it needs to be forgotten.
 During those 4 hours, the key will be used for actions (eg decrypt messages).
 After those 4 hours, the user will be prompted for a pass phrase with a modal / alert to re-enter it, at which point it will be again remembered for 4 hours.

 If app gets killed, pass phrase gets forgotten.
 */
