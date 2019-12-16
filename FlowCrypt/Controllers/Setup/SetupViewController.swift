//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit

final class SetupViewController: ASViewController<ASTableNode> {
    private let imap: Imap
    private let userService: UserServiceType
    private let router: GlobalRouterType
    private let storage: DataManagerType
    private let decorator: SetupDecoratorType
    private let core: Core
    private let keyMethods: KeyMethodsType

    private var setupAction = SetupAction.recoverKey
    private var fetchedEncryptedPrvs: [KeyDetails] = []

    // TODO: refactor with state approach
    private var subtitle = "setup_description".localized {
        didSet {
            node.reloadRows(at: [IndexPath(row: Parts.description.rawValue, section: 0)], with: .fade)
        }
    }
    private var actionButton = SetupButtonType.loadAccount {
        didSet {
            node.reloadRows(at: [IndexPath(row: Parts.action.rawValue, section: 0)], with: .fade)
        }
    }
    private var passPhrase: String?

    init(
        imap: Imap = Imap(),
        userService: UserServiceType = UserService.shared,
        router: GlobalRouterType = GlobalRouter(),
        storage: DataManagerType = DataManager.shared,
        decorator: SetupDecoratorType = SetupDecorator(),
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
        fetchBackupsAndRenderResult()
    }
}

// MARK: - Setup

extension SetupViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        observeKeyboardNotifications()

        subtitle = "setup_description".localized
    }

    private func observeKeyboardNotifications() {
        _ = keyboardHeight
            .map { UIEdgeInsets(top: 0, left: 0, bottom: $0 + 5, right: 0) }
            .subscribe(onNext: { [weak self] inset in
                self?.node.contentInset = inset
                self?.node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
            })
    }
}

// MARK: - Key Setup

extension SetupViewController {
    private func fetchBackupsAndRenderResult() {
        showSpinner()
        Promise<Void> { [weak self] in
            guard let self = self else { return }
            let backupData = try await(self.imap.searchBackups())
            let parsed = try self.core.parseKeys(armoredOrBinary: backupData)
            self.fetchedEncryptedPrvs = parsed.keyDetails.filter { $0.private != nil }
        }.then(on: .main) { [weak self] in
            self?.handleBackupsFetchResult()
        }.catch(on: .main) { [weak self] error in
            self?.renderNoBackupsFoundOptions("setup_action_failed".localized, error: error)
        }
    }

    private func handleBackupsFetchResult() {
        hideSpinner()
        if fetchedEncryptedPrvs.isEmpty {
            // TODO: Anton -
            let user = DataManager.shared.email ?? "unknown_title".localized
            let msg = "setup_no_backups".localized + user
            renderNoBackupsFoundOptions(msg)
        } else {
            subtitle = "Found \(self.fetchedEncryptedPrvs.count) key backup\(self.fetchedEncryptedPrvs.count > 1 ? "s" : "")"
        }
    }

    private func renderNoBackupsFoundOptions(_ msg: String, error: Error? = nil) {
        let errStr = error != nil ? "\n\n\(error!)" : ""
        let alert = UIAlertController(title: "Notice", message: msg + errStr, preferredStyle: .alert)
        if error == nil { // no backous found, not an error: show option to create a key or import key
            alert.addAction(UIAlertAction(title: "Import existing Private Key", style: .default) { [weak self] _ in
                self?.handleImportKey()
            })
            alert.addAction(UIAlertAction(title: "Create new Private Key", style: .default) { [weak self] _ in
                self?.handleCreateKey()
            })
        }
        alert.addAction(UIAlertAction(title: "setup_use_otherAccount".localized, style: .default) { [weak self] _ in
            self?.userService.signOut().then(on: .main) { [weak self] in
                if self?.navigationController?.popViewController(animated: true) == nil {
                    self?.router.reset() // in case app got restarted and no view to pop
                }
            }.catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Could not sign out")
            }
        })
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.fetchBackupsAndRenderResult()
        })
        present(alert, animated: true, completion: nil)
    }

    private func handleImportKey() {
        let viewController = ImportKeyViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func handleCreateKey() {
        subtitle = "Create a new OpenPGP Private Key"
        actionButton = .createKey
        setupAction = SetupAction.createKey
        // todo - show strength bar while typed so that user can choose the strength they need
    }

    private func recoverAccountWithBackups(with passPhrase: String) {
        let matchingKeyBackups = keyMethods.filterByPassPhraseMatch(keys: fetchedEncryptedPrvs, passPhrase: passPhrase)

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
        // TODO: Anton -
        guard let email = DataManager.shared.email, !email.isEmpty else { throw AppErr.unexpected("Missing user email") }
        guard let name = DataManager.shared.email, !name.isEmpty else { throw AppErr.unexpected("Missing user name") }
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
            try await(Imap().sendMail(mime: backupEmail.mimeEncoded))
        }
    }

    private func storePrvs(prvs: [KeyDetails], passPhrase: String, source: KeySource) throws {
        storage.addKeys(keyDetails: prvs, passPhrase: passPhrase, source: source)
    }
}

// MARK: - Events

extension SetupViewController {
    private func handleButtonPressed() {
        view.endEditing(true)
        guard let passPhrase = passPhrase else { return }
        guard !passPhrase.isEmpty else {
            showAlert(message: "setup_enter_pass_phrase".localized)
            return
        }
        showSpinner()

        switch setupAction {
        case .recoverKey:
            recoverAccountWithBackups(with: passPhrase)
        case .createKey:
            setupAccountWithGeneratedKey(with: passPhrase)
        }
    }

    private func useOtherAccount() {
        userService.signOut().then(on: .main) { [weak self] _ in
            self?.router.reset()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not switch accounts")
        }
    }

    private func moveToMainFlow() {
        GlobalRouter().reset()
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
                    title: self.decorator.subtitleStyle(self.subtitle),
                    insets: self.decorator.subTitleInset
                )
            case .passPhrase:
                return TextFieldCellNode(input: self.decorator.textFieldStyle) { [weak self] action in
                    guard case let .didEndEditing(value) = action else { return }
                    self?.passPhrase = value
                }
                .onReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    return true
                }
            case .action:
                return SetupButtonNode(
                    title: self.decorator.titleForAction(button: self.setupAction),
                    insets: self.decorator.buttonInsets) { [weak self] in
                        self?.handleButtonPressed()
                }
            case .optionalAction:
                return SetupButtonNode(
                    title: self.decorator.useAnotherAccountTitle,
                    insets: self.decorator.optionalButtonInsets,
                    color: .white) { [weak self] in
                        self?.useOtherAccount()
                }
            case .divider:
                return DividerNode(inset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
            }
        }
    }
}
