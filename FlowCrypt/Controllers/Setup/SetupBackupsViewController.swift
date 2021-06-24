//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

final class SetupBackupsViewController: TableNodeViewController, PassPhraseSaveable {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, saveLocally, saveInMemory, action, optionalAction
    }

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)
    private let router: GlobalRouterType
    private let decorator: SetupViewDecorator
    private let core: Core
    private let keyMethods: KeyMethodsType
    private let user: UserId
    private let fetchedEncryptedKeys: [KeyDetails]
    private let keyStorage: KeyStorageType
    let passPhraseStorage: PassPhraseStorageType

    private var passPhrase: String?

    var shouldSaveLocally = true {
        didSet {
            handleSelectedPassPhraseOption()
        }
    }

    var passPhraseIndexes: [IndexPath] {
        [Parts.saveLocally, Parts.saveInMemory]
            .map { IndexPath(row: $0.rawValue, section: 0) }
    }

    init(
        fetchedEncryptedKeys: [KeyDetails],
        router: GlobalRouterType = GlobalRouter(),
        keyStorage: KeyStorageType = KeyDataStorage(),
        decorator: SetupViewDecorator = SetupViewDecorator(),
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        user: UserId,
        passPhraseStorage: PassPhraseStorageType = PassPhraseStorage(
            storage: EncryptedStorage(),
            emailProvider: DataService.shared
        )
    ) {
        self.fetchedEncryptedKeys = fetchedEncryptedKeys
        self.router = router
        self.keyStorage = keyStorage
        self.decorator = decorator
        self.core = core
        self.keyMethods = keyMethods
        self.user = user
        self.passPhraseStorage = passPhraseStorage

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
}

// MARK: - Setup
extension SetupBackupsViewController {
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

// MARK: - Actions
extension SetupBackupsViewController {
    private func handleBackups() {
        guard fetchedEncryptedKeys.isNotEmpty else {
            return assertionFailure("Should be handled in SetupInitialViewController")
        }

        node.reloadData()

        node.visibleNodes
            .compactMap { $0 as? TextFieldCellNode }
            .first?
            .becomeFirstResponder()
    }

    private func recoverAccount(with backups: [KeyDetails], and passPhrase: String) {
        logger.logInfo("Start recoverAccount with \(backups.count)")
        let matchingKeyBackups = Set(keyMethods.filterByPassPhraseMatch(keys: backups, passPhrase: passPhrase))

        logger.logInfo("matchingKeyBackups = \(matchingKeyBackups.count)")
        guard matchingKeyBackups.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        // save pass phrase
        matchingKeyBackups
            .map {
                PassPhrase(value: passPhrase, longid: $0.longid)
            }
            .forEach {
                passPhraseStorage.savePassPhrase(with: $0, inStorage: shouldSaveLocally)
            }

        // save keys
        keyStorage.addKeys(keyDetails: Array(matchingKeyBackups), source: .backup)

        moveToMainFlow()
    }

    private func handleButtonPressed() {
        view.endEditing(true)
        guard let passPhrase = passPhrase else { return }

        guard passPhrase.isNotEmpty else {
            showPassPhraseErrorAlert()
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
extension SetupBackupsViewController: ASTableDelegate, ASTableDataSource {
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
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .loadAccount),
                    insets: self.decorator.insets.buttonInsets
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleButtonPressed()
                }
                .then {
                    $0.button.accessibilityIdentifier = "load_account"
                }
            case .optionalAction:
                return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
                    self?.handleOtherAccount()
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
            shouldSaveLocally = true
        case .saveInMemory:
            shouldSaveLocally = false
        default:
            break
        }
    }
}
