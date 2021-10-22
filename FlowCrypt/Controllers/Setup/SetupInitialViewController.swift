//
//  SetupInitialViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 26.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * Initial controller for setup flow which is responsible for searching backups and
 * then redirecting user to appropriate setup flow.
 * - In case backup keys are found, user will be redirected to **SetupBackupsViewController**
 * - In case there are no backups, user will have two options presented in this view:
 *      - Import key - **SetupManuallyImportKeyViewController**
 *      - Create new key - **SetupGenerateKeyViewController**
 */
final class SetupInitialViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, description, createKey, importKey, anotherAccount
    }

    private enum State {
        case idle, decidingIfEKMshouldBeUsed, fetchingKeysFromEKM, searchingKeyBackupsInInbox, noKeyBackupsInInbox, gmailUnauthorised, error(Error)

        var numberOfRows: Int {
            switch self {
            // title
            case .idle, .decidingIfEKMshouldBeUsed, .fetchingKeysFromEKM:
                return 1
            // title, loading
            case .searchingKeyBackupsInInbox:
                return 2
            case .error, .gmailUnauthorised:
                return 3
            case .noKeyBackupsInInbox:
                return Parts.allCases.count
            }
        }
    }
    
    private struct Constants {
        static let unauthorizedAPICode = 403
    }

    private var state = State.idle {
        didSet { handleNewState() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    private let backupService: BackupServiceType
    private let user: UserId
    private let router: GlobalRouterType
    private let decorator: SetupViewDecorator
    private let clientConfiguration: ClientConfiguration
    private let emailKeyManagerApi: EmailKeyManagerApiType

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        user: UserId,
        backupService: BackupServiceType = BackupService(),
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator(),
        clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService(),
        emailKeyManagerApi: EmailKeyManagerApiType = EmailKeyManagerApi()
    ) {
        self.user = user
        self.backupService = backupService
        self.router = router
        self.decorator = decorator
        self.clientConfiguration = clientConfigurationService.getSavedClientConfigurationForCurrentUser()
        self.emailKeyManagerApi = emailKeyManagerApi

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        state = .decidingIfEKMshouldBeUsed
    }
}

// MARK: - Action Handling
extension SetupInitialViewController {

    private func handleNewState() {
        logger.logInfo("Changed to new state \(state)")

        switch state {
        case .searchingKeyBackupsInInbox:
            searchKeyBackupsInInbox()
        case .decidingIfEKMshouldBeUsed:
            decideIfEKMshouldBeUsed()
        case .fetchingKeysFromEKM:
            fetchKeysFromEKM()
        case .error, .idle, .noKeyBackupsInInbox, .gmailUnauthorised:
            break
        }
        node.reloadData()
    }

    private func searchKeyBackupsInInbox() {
        if !clientConfiguration.canBackupKeys {
            logger.logInfo("Skipping backups searching because canBackupKeys == false")
            proceedToSetupWith(keys: [])
            return
        }

        logger.logInfo("Searching for backups in inbox")

        Task {
            do {
                let keys = try await backupService.fetchBackupsFromInbox(for: user)
                proceedToSetupWith(keys: keys)
            } catch {
                handle(error: error)
            }
        }
    }

    private func handleOtherAccount() {
        router.signOut()
    }

    private func handle(error: Error) {
        if let gmailServiceError = error as? GmailServiceError,
           let gmailError = gmailServiceError.underlyingError,
           (gmailError as NSError).code == Constants.unauthorizedAPICode {
            state = .gmailUnauthorised
            return
        }
        handleCommon(error: error)
        state = .error(error)
    }

    private func decideIfEKMshouldBeUsed() {
        switch clientConfiguration.checkUsesEKM() {
        case .usesEKM:
            state = .fetchingKeysFromEKM
        case .doesNotUseEKM:
            state = .searchingKeyBackupsInInbox
        case .inconsistentClientConfiguration(let error):
            showAlert(message: error.description) { [weak self] in
                self?.router.signOut()
            }
        }
    }

    private func fetchKeysFromEKM() {
        emailKeyManagerApi.getPrivateKeys()
            .then(on: .main) { [weak self] result in
                switch result {
                case .success(keys: let keys):
                    self?.proceedToSetupWithEKMKeys(keys: keys)
                case .noKeys:
                    self?.showRetryAlert(
                        message: "organisational_rules_ekm_empty_private_keys_error".localized,
                        onRetry: {
                            self?.state = .fetchingKeysFromEKM
                        },
                        onOk: {
                            self?.router.signOut()
                        }
                    )
                case .keysAreNotDecrypted:
                    self?.showAlert(message: "organisational_rules_ekm_keys_are_not_decrypted_error".localized, onOk: {
                        self?.router.signOut()
                    })
                }
            }
            .catch { [weak self] error in
                if case .noPrivateKeysUrlString = error as? EmailKeyManagerApiError {
                    return
                }
                self?.showAlert(message: error.localizedDescription, onOk: {
                    self?.state = .decidingIfEKMshouldBeUsed
                })
            }
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension SetupInitialViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        state.numberOfRows
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .idle, .decidingIfEKMshouldBeUsed, .fetchingKeysFromEKM:
                return ASCellNode()
            case .searchingKeyBackupsInInbox:
                return self.searchStateNode(for: indexPath)
            case .error(let error):
                return self.errorStateNode(for: indexPath, error: error)
            case .noKeyBackupsInInbox:
                return self.noKeysStateNode(for: indexPath)
            case .gmailUnauthorised:
                return self.unauthStateNode(for: indexPath)
            }
        }
    }
}

// MARK: - UI
extension SetupInitialViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self

        title = decorator.sceneTitle(for: .setup)
    }

    private func searchStateNode(for indexPath: IndexPath) -> ASCellNode {
        switch indexPath.row {
        case 0:
            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: self.decorator.title(for: .setup),
                    insets: self.decorator.insets.titleInset,
                    backgroundColor: .backgroundColor
                )
            )
        default:
            return TextCellNode(input: .loading(with: CGSize(width: 40, height: 40)))
        }
    }

    private func noKeysStateNode(for indexPath: IndexPath) -> ASCellNode {
        guard let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }

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
                    title: self.decorator.subtitle(for: .noBackups),
                    insets: self.decorator.insets.subTitleInset,
                    backgroundColor: .backgroundColor
                )
            )
        case .createKey:
            let input = ButtonCellNode.Input(
                title: self.decorator.buttonTitle(for: .createKey),
                insets: self.decorator.insets.buttonInsets
            )
            return ButtonCellNode(input: input) { [weak self] in
                self?.proceedToCreatingNewKey()
            }
        case .importKey:
            let input = ButtonCellNode.Input(
                title: self.decorator.buttonTitle(for: .importKey),
                insets: self.decorator.insets.buttonInsets
            )
            return ButtonCellNode(input: input) { [weak self] in
                self?.proceedToKeyImport()
            }
        case .anotherAccount:
            return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
                self?.handleOtherAccount()
            }
        }
    }

    private func errorStateNode(for indexPath: IndexPath, error: Error) -> ASCellNode {
        switch indexPath.row {
        case 0:
            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: self.decorator.title(for: .setup),
                    insets: self.decorator.insets.titleInset,
                    backgroundColor: .backgroundColor
                )
            )
        case 1:
            return TextCellNode(
                input: .init(
                    backgroundColor: .backgroundColor,
                    title: error.localizedDescription,
                    withSpinner: false,
                    size: CGSize(width: 200, height: 200)
                )
            )
        case 2:
            return ButtonCellNode(input: .retry) { [weak self] in
                self?.state = .searchingKeyBackupsInInbox
            }
        default:
            return ASCellNode()
        }
    }

    private func unauthStateNode(for indexPath: IndexPath) -> ASCellNode {
        switch indexPath.row {
        case 0:
            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: self.decorator.title(for: .setup),
                    insets: self.decorator.insets.titleInset,
                    backgroundColor: .backgroundColor
                )
            )
        case 1:
            return TextCellNode(
                input: .init(
                    backgroundColor: .backgroundColor,
                    title: "gmail_service_no_access_to_account_message".localized,
                    withSpinner: false,
                    size: CGSize(width: 200, height: 200)
                )
            )
        case 2:
            return ButtonCellNode(input: .signInAgain) { [weak self] in
                self?.router.signOut()
            }
        default:
            return ASCellNode()
        }
    }
}

// MARK: - Navigation
extension SetupInitialViewController {
    private func proceedToKeyImport() {
        let viewController = SetupManuallyImportKeyViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToCreatingNewKey() {
        let viewController = SetupGenerateKeyViewController(user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
    private func proceedToSetupWithEKMKeys(keys: [CoreRes.ParseKeys]) {
        let viewController = SetupEKMKeyViewController(user: user, keys: keys)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToSetupWith(keys: [KeyDetails]) {
        logger.logInfo("Finish searching for backups in inbox")

        if keys.isEmpty {
            logger.logInfo("No key backups found in inbox")
            state = .noKeyBackupsInInbox
        } else {
            logger.logInfo("\(keys.count) key backups found in inbox")
            let viewController = SetupBackupsViewController(fetchedEncryptedKeys: keys, user: user)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - Buttons input
private extension ButtonCellNode.Input {
    static var signInAgain: ButtonCellNode.Input {
        return .init(
            title: "sign_in_again"
                .localized
                .attributed(.bold(16), color: .white, alignment: .center),
            insets: UIEdgeInsets(top: 16, left: 24, bottom: 8, right: 24),
            color: .main
        )
    }
}
