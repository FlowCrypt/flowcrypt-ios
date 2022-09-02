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
                return 4
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

    private let decorator: SetupViewDecorator
    private let clientConfiguration: ClientConfiguration
    private let emailKeyManagerApi: EmailKeyManagerApiType
    private let appContext: AppContextWithUser

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        appContext: AppContextWithUser,
        decorator: SetupViewDecorator = SetupViewDecorator(),
        emailKeyManagerApi: EmailKeyManagerApiType? = nil
    ) async throws {
        self.appContext = appContext
        self.decorator = decorator
        let clientConfiguration = try await appContext.clientConfigurationService.configuration
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
                let keys = try await appContext.getBackupService().fetchBackupsFromInbox(for: appContext.userId)
                proceedToSetupWith(keys: keys)
            } catch {
                handle(error: error)
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await appContext.globalRouter.signOut(appContext: appContext)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func handle(error: Error) {
        showAlert(message: error.errorMessage)
        state = .error(error)
    }

    private func decideIfEKMshouldBeUsed() {
        do {
            switch try clientConfiguration.checkUsesEKM() {
            case .usesEKM:
                state = .fetchingKeysFromEKM
            case .doesNotUseEKM:
                state = .searchingKeyBackupsInInbox
            case .inconsistentClientConfiguration(let error):
                showAlert(message: error.description) { [weak self] in
                    self?.signOut()
                }
            }
        } catch {
            showAlert(message: error.errorMessage)
        }
    }

    private func fetchKeysFromEKM() {
        Task {
            do {
                let idToken = try await IdTokenUtils.getIdToken(userEmail: appContext.user.email)
                let keys = try await emailKeyManagerApi.getPrivateKeys(idToken: idToken)
                guard keys.isNotEmpty else {
                    showRetryAlert(for: "organisational_rules_ekm_empty_private_keys_error".localized)
                    return
                }
                proceedToSetupWithEKMKeys(keys: keys)
            } catch {
                showRetryAlert(for: error.errorMessage)
            }
        }
    }

    func showRetryAlert(for errorMessage: String) {
        showRetryAlert(
            message: errorMessage,
            cancelButtonTitle: "log_out".localized,
            onRetry: { [weak self] _ in
                self?.state = .fetchingKeysFromEKM
            },
            onCancel: { [weak self] _ in
                self?.signOut()
            }
        )
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
                title: self.decorator.buttonTitle(for: .createKey)
            )
            return ButtonCellNode(input: input) { [weak self] in
                self?.proceedToCreatingNewKey()
            }.then {
                $0.button.accessibilityIdentifier = "aid-create-new-key-button"
            }
        case .importKey:
            let input = ButtonCellNode.Input(
                title: self.decorator.buttonTitle(for: .importKey)
            )
            return ButtonCellNode(input: input) { [weak self] in
                self?.proceedToKeyImport()
            }.then {
                $0.button.accessibilityIdentifier = "aid-import-my-key-button"
            }
        case .anotherAccount:
            return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
                self?.signOut()
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
                    title: error.errorMessage,
                    withSpinner: false,
                    size: CGSize(width: 200, height: 200)
                )
            )
        case 2:
            return ButtonCellNode(input: .retry) { [weak self] in
                self?.state = .searchingKeyBackupsInInbox
            }
        case 3:
            return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
                self?.signOut()
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
        Task {
            do {
                let viewController = try await SetupGenerateKeyViewController(appContext: appContext)
                navigationController?.pushViewController(viewController, animated: true)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func proceedToSetupWithEKMKeys(keys: [KeyDetails]) {
        let viewController = SetupEKMKeyViewController(appContext: appContext, keys: keys)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToSetupWith(keys: [KeyDetails]) {
        logger.logInfo("Finish searching for backups in inbox")

        if keys.isEmpty {
            logger.logInfo("No key backups found in inbox")
            state = .noKeyBackupsInInbox
        } else {
            logger.logInfo("\(keys.count) key backups found in inbox")
            let viewController = SetupBackupsViewController(appContext: appContext, fetchedEncryptedKeys: keys)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
