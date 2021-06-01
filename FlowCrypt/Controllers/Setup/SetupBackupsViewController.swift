//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

final class SetupBackupsViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, action, optionalAction
    }

    private let router: GlobalRouterType
    private let storage: DataServiceType & KeyDataServiceType
    private let decorator: SetupViewDecorator
    private let core: Core
    private let keyMethods: KeyMethodsType
    private let user: UserId
    private let fetchedEncryptedKeys: [KeyDetails]

    private var passPhrase: String?
    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        fetchedEncryptedKeys: [KeyDetails],
        router: GlobalRouterType = GlobalRouter(),
        storage: DataServiceType & KeyDataServiceType = DataService.shared,
        decorator: SetupViewDecorator = SetupViewDecorator(),
        core: Core = Core.shared,
        keyMethods: KeyMethodsType = KeyMethods(),
        user: UserId
    ) {
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

        let matchingKeyBackups = keyMethods.filterByPassPhraseMatch(keys: backups, passPhrase: passPhrase)

        guard matchingKeyBackups.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        storage.addKeys(keyDetails: matchingKeyBackups, passPhrase: passPhrase, source: .backup)

        moveToMainFlow()
    }

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
                return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
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
