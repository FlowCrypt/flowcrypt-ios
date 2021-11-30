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
        case idle, decidingIfEKMshouldBeUsed, fetchingKeysFromEKM, searchingKeyBackupsInInbox, noKeyBackupsInInbox, error(Error)

        var numberOfRows: Int {
            switch self {
            // title
            case .idle, .decidingIfEKMshouldBeUsed, .fetchingKeysFromEKM:
                return 1
            // title, loading
            case .searchingKeyBackupsInInbox:
                return 2
            case .error:
                return 3
            case .noKeyBackupsInInbox:
                return Parts.allCases.count
            }
        }
    }

    private var state = State.idle {
        didSet { handleNewState() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    private let backupService: BackupServiceType
    private let service: ServiceActor
    private let user: UserId
    private let router: GlobalRouterType
    private let decorator: SetupViewDecorator
    private let clientConfiguration: ClientConfiguration
    private let emailKeyManagerApi: EmailKeyManagerApiType
    private let appContext: AppContext

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        appContext: AppContext,
        user: UserId,
        backupService: BackupServiceType? = nil,
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator(),
        emailKeyManagerApi: EmailKeyManagerApiType? = nil
    ) {
        self.appContext = appContext
        self.user = user
        let backupService = backupService ?? appContext.getBackupService()
        self.backupService = backupService
        self.service = ServiceActor(backupService: backupService)
        self.router = router
        self.decorator = decorator
        let clientConfiguration = appContext.clientConfigurationService.getSaved(for: user.email)
        self.emailKeyManagerApi = emailKeyManagerApi ?? EmailKeyManagerApi(clientConfiguration: clientConfiguration)
        self.clientConfiguration = clientConfiguration
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
        case .error, .idle, .noKeyBackupsInInbox:
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
                let keys = try await service.fetchBackupsFromInbox(for: user)
                proceedToSetupWith(keys: keys)
            } catch {
                handle(error: error)
            }
        }
    }

    private func handleOtherAccount() {
        router.signOut(appContext: appContext)
    }

    private func handle(error: Error) {
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
                guard let self = self else { return }
                self.router.signOut(appContext: self.appContext)
            }
        }
    }

    private func fetchKeysFromEKM() {
        Task {
            do {
                let result = try await emailKeyManagerApi.getPrivateKeys(currentUserEmail: user.email)
                switch result {
                case .success(keys: let keys):
                    proceedToSetupWithEKMKeys(keys: keys)
                case .noKeys:
                    showRetryAlert(
                        message: "organisational_rules_ekm_empty_private_keys_error".localized,
                        onRetry: { [weak self] in
                            self?.state = .fetchingKeysFromEKM
                        },
                        onOk: { [weak self] in
                            guard let self = self else { return }
                            self.router.signOut(appContext: self.appContext)
                        }
                    )
                case .keysAreNotDecrypted:
                    showAlert(message: "organisational_rules_ekm_keys_are_not_decrypted_error".localized, onOk: { [weak self] in
                        guard let self = self else { return }
                        self.router.signOut(appContext: self.appContext)
                    })
                }
            } catch {
                if case .noPrivateKeysUrlString = error as? EmailKeyManagerApiError {
                    return
                }
                showAlert(message: error.localizedDescription, onOk: { [weak self] in
                    self?.state = .decidingIfEKMshouldBeUsed
                })
            }
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
            return TextCellNode.loading
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
}

// MARK: - Navigation
extension SetupInitialViewController {
    private func proceedToKeyImport() {
        let viewController = SetupManuallyImportKeyViewController(appContext: appContext)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToCreatingNewKey() {
        let viewController = SetupGenerateKeyViewController(appContext: appContext, user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
    private func proceedToSetupWithEKMKeys(keys: [KeyDetails]) {
        let viewController = SetupEKMKeyViewController(appContext: appContext, user: user, keys: keys)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToSetupWith(keys: [KeyDetails]) {
        logger.logInfo("Finish searching for backups in inbox")

        if keys.isEmpty {
            logger.logInfo("No key backups found in inbox")
            state = .noKeyBackupsInInbox
        } else {
            logger.logInfo("\(keys.count) key backups found in inbox")
            let viewController = SetupBackupsViewController(appContext: appContext, fetchedEncryptedKeys: keys, user: user)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let backupService: BackupServiceType

    init(backupService: BackupServiceType) {
        self.backupService = backupService
    }

    func fetchBackupsFromInbox(for userId: UserId) async throws -> [KeyDetails] {
        return try await backupService.fetchBackupsFromInbox(for: userId)
    }
}
