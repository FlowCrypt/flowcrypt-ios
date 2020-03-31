//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit
import FlowCryptUI

final class SetupViewController: ASViewController<ASTableNode> {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, action, optionalAction
    }

    private let imap: Imap
    private let userService: UserServiceType
    private let router: GlobalRouterType
    private let storage: DataServiceType
    private let decorator: SetupViewDecoratorType
    private let core: Core
    private let keyMethods: KeyMethodsType

    private var passPhrase: String?

    enum SetupError: Error {
        /// fetched keys error
        case emptyFetchedKeys
        /// error while key parsing (associated error for verbose message)
        case parseKey(Error)
        /// no backups found while searching in imap
        case noBackups
    }

    enum State {
        /// initial state
        case idle
        /// start searching backups
        case searchingBackups
        /// found backup data
        case backups(Data)
        /// encrypted keys found
        case fetchedEncrypted([KeyDetails])
        /// creating new key
        case createKey
        /// error state
        case error(SetupError)
    }

    private var state: State = .idle {
        didSet {
            handle(newState: state)
        }
    }

    init(
        imap: Imap = Imap.shared,
        userService: UserServiceType = UserService.shared,
        router: GlobalRouterType = GlobalRouter(),
        storage: DataServiceType = DataService.shared,
        decorator: SetupViewDecoratorType = SetupViewDecorator(),
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(core: .shared)
    ) {
        self.imap = imap
        self.userService = userService
        self.router = router
        self.storage = storage
        self.decorator = decorator
        self.core = core
        self.keyMethods = keyMethods
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        state = .searchingBackups
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        node.reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Setup

extension SetupViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        observeKeyboardNotifications()

        state = .idle
    }

    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let self = self else { return }
                self.adjustForKeyboard(height: self.keyboardHeight(from: notification))
            }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                self?.adjustForKeyboard(height: 0)
            }
    }

    private func adjustForKeyboard(height: CGFloat) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
    }
}

// MARK: - State Handling
extension SetupViewController {
    private func handle(newState: State) {
        hideSpinner()
        switch newState {
        case .idle:
            node.reloadData()
        case .searchingBackups:
            searchBackups()
        case let .backups(data):
            reloadNodes()
            fetchEnctyptedKeys(with: data)
        case let .fetchedEncrypted(details):
            handleBackupsFetchResult(with: details)
        case .error(let error):
            handleError(with: error)
        case .createKey:
            handleCreateKey()
        }
    }

    private func searchBackups() {
        guard let email = storage.email else {
            assertionFailure(); return
        }
        
        showSpinner()


        self.imap.searchBackups(for: email)
            .then(on: .main) { [weak self] data in
                self?.state = .backups(data)
            }
            .catch(on: .main) { [weak self] _ in
                self?.state = .error(.noBackups)
            }
    }

    private func fetchEnctyptedKeys(with backupData: Data) {
        showSpinner()

        do {
            let parsed = try self.core.parseKeys(armoredOrBinary: backupData)
            let keys = parsed.keyDetails.filter { $0.private != nil }
            state = .fetchedEncrypted(keys)
        } catch let error {
            state = .error(.parseKey(error))
        }
    }

    private func handleBackupsFetchResult(with keys: [KeyDetails]) {
        guard keys.isNotEmpty else {
            state = .error(.emptyFetchedKeys)
            return
        }

        reloadNodes()

        node.visibleNodes
            .compactMap { $0 as? TextFieldCellNode }
            .first?
            .becomeFirstResponder()
    }

    private func handleCreateKey() {
        reloadNodes()
    }

    private func reloadNodes() {
        let indexes =  [
            IndexPath(row: Parts.action.rawValue, section: 0),
            IndexPath(row: Parts.description.rawValue, section: 0)
        ]
        node.reloadRows(at: indexes, with: .fade)
    }
}

// MARK: - Error Handling

extension SetupViewController {
    private func handleError(with error: SetupError) {
        switch error {
        case .emptyFetchedKeys:
            let user = DataService.shared.email ?? "unknown_title".localized
            let msg = "setup_no_backups".localized + user
            showSearchBackupError(with: msg)
        case .noBackups:
            showSearchBackupError(with: "setup_action_failed".localized)
        case .parseKey(let error):
            showErrorAlert(with: "setup_action_failed".localized, error: error)
        }
    }

    private func errorAlert(with message: String) -> UIAlertController {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)

        let useOtherAccountAction = UIAlertAction(
            title: "setup_use_otherAccount".localized,
            style: .default) { [weak self] _ in
                self?.handleOtherAccount()
            }

        let retryAction = UIAlertAction(
            title: "Retry",
            style: .default) { [weak self] _ in
                self?.state = .idle
                self?.state = .searchingBackups
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
            style: .default) { [weak self] _ in
                self?.handleImportKey()
            }

        let createNewPrivateKeyAction = UIAlertAction(
            title: "setup_action_create_new".localized,
            style: .default) { [weak self] _ in
                self?.state = .createKey
            }

        alert.addAction(importAction)
        alert.addAction(createNewPrivateKeyAction)

        present(alert, animated: true, completion: nil)
    }
}


// MARK: - Recover account

extension SetupViewController {
    private func recoverAccountWithBackups(with passPhrase: String) {
        guard case let .fetchedEncrypted(details) = state else { assertionFailure(); return }

        let matchingKeyBackups = keyMethods.filterByPassPhraseMatch(keys: details, passPhrase: passPhrase)

        guard matchingKeyBackups.count > 0 else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        try! storePrvs(prvs: matchingKeyBackups, passPhrase: passPhrase, source: .generated)
        moveToMainFlow()
    }

    private func setupAccountWithGeneratedKey(with passPhrase: String) {
        Promise { [weak self] in
            guard let self = self else { return }
            let userId = try self.getUserId()
            try await(self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))
            let encryptedPrv = try self.core.generateKey(passphrase: passPhrase, variant: .curve25519, userIds: [userId])
            try await(self.backupPrvToInbox(prv: encryptedPrv.key, userId: userId))
            try self.storePrvs(prvs: [encryptedPrv.key], passPhrase: passPhrase, source: .generated)
            try await(self.alertAndSkipOnRejection(AttesterApi.shared.updateKey(email: userId.email, pubkey: encryptedPrv.key.public), fail: "Failed to submit Public Key"))
            try await(self.alertAndSkipOnRejection(AttesterApi.shared.testWelcome(email: userId.email, pubkey: encryptedPrv.key.public), fail: "Failed to send you welcome email"))
        }.then(on: .main) { [weak self] in
            self?.moveToMainFlow()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not finish setup, please try again")
        }
    }

    private func validateAndConfirmNewPassPhraseOrReject(passPhrase: String) -> Promise<Void> {
        return Promise {
            let strength = try self.core.zxcvbnStrengthBar(passPhrase: passPhrase)
            guard strength.word.pass else { throw AppErr.user("Pass phrase strength: \(strength.word.word)\ncrack time: \(strength.time)\n\nWe recommend to use 5-6 unrelated words as your Pass Phrase.") }
            let confirmPassPhrase = try await(self.awaitUserPassPhraseEntry(title: "Confirm Pass Phrase"))
            guard confirmPassPhrase != nil else { throw AppErr.silentAbort }
            guard confirmPassPhrase == passPhrase else { throw AppErr.user("Pass phrases don't match") }
        }
    }

    private func getUserId() throws -> UserId {
        guard let email = DataService.shared.email, !email.isEmpty else { throw AppErr.unexpected("Missing user email") }
        guard let name = DataService.shared.email, !name.isEmpty else { throw AppErr.unexpected("Missing user name") }
        return UserId(email: email, name: name)
    }

    private func backupPrvToInbox(prv: KeyDetails, userId: UserId) -> Promise<Void> {
        return Promise { () -> Void in
            guard prv.isFullyEncrypted ?? false else { throw AppErr.unexpected("Private Key must be fully enrypted before backing up") }
            let filename = "flowcrypt-backup-\(userId.email.replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)).key"
            let backupEmail = try self.core.composeEmail(msg: SendableMsg(
                text: "setup_backup_email".localized,
                to: [userId.toMime()],
                cc: [],
                bcc: [],
                from: userId.toMime(),
                subject: "Your FlowCrypt Backup",
                replyToMimeMsg: nil,
                atts: [SendableMsg.Att(name: filename, type: "text/plain", base64: prv.private!.data().base64EncodedString())] // !crash ok
            ), fmt: .plain, pubKeys: nil)
            try await(Imap.shared.sendMail(mime: backupEmail.mimeEncoded))
        }
    }

    private func storePrvs(prvs: [KeyDetails], passPhrase: String, source: KeySource) throws {
        storage.addKeys(keyDetails: prvs, passPhrase: passPhrase, source: source)
    }
}

// MARK: - Events

extension SetupViewController {
    private func handleImportKey() {
        let viewController = ImportKeyViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func handleButtonPressed() {
        view.endEditing(true)
        guard let passPhrase = passPhrase else { return }

        guard passPhrase.isNotEmpty else {
            showAlert(message: "setup_enter_pass_phrase".localized)
            return
        }

        showSpinner()

        switch state {
        case .createKey: setupAccountWithGeneratedKey(with: passPhrase)
        default: recoverAccountWithBackups(with: passPhrase)
        }
    }

    private func handleOtherAccount() {
        userService.signOut()
            .then(on: .main) { [weak self] _ in
                self?.router.proceed()
            }.catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Could not switch accounts")
            }
    }

    private func moveToMainFlow() {
        GlobalRouter().proceed()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    title: self.decorator.title,
                    insets: self.decorator.titleInset
                )
            case .description:
                return SetupTitleNode(
                    title: self.decorator.subtitle(for: self.state),
                    insets: self.decorator.subTitleInset
                )
            case .passPhrase:
                return TextFieldCellNode(input: self.decorator.textFieldStyle) { [weak self] action in
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
                    title: self.decorator.buttonTitle(for: self.state),
                    insets: self.decorator.buttonInsets
                ) { [weak self] in
                    self?.handleButtonPressed()
                }
                .then {
                    $0.button.accessibilityIdentifier = "load_account"
                }
            case .optionalAction:
                return ButtonCellNode(
                    title: self.decorator.useAnotherAccountTitle,
                    insets: self.decorator.optionalButtonInsets,
                    color: .white
                ) { [weak self] in
                    self?.handleOtherAccount()
                }
            case .divider:
                return DividerCellNode(inset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
            }
        }
    }
}
