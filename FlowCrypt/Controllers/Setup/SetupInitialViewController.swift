//
//  SetupInitialViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 26.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

// TODO: - ANTON - add refresh controller
final class SetupInitialViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, description, createKey, importKey, anotherAccount
    }

    private enum State {
        case idle, searching, noKeyBackups, error(Error)

        var numberOfRows: Int {
            switch self {
            // title
            case .idle:
                return 1
            // title, loading
            case .searching:
                return 2
            case .error:
                return 3
            case .noKeyBackups:
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
    private let user: UserId
    private let router: GlobalRouterType
    private let decorator: SetupViewDecorator

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        user: UserId,
        backupService: BackupServiceType = BackupService(),
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator()
    ) {
        self.user = user
        self.backupService = backupService
        self.router = router
        self.decorator = decorator

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        state = .searching
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        state = .searching
    }
}

// MARK: - Action Handling
extension SetupInitialViewController {

    private func handleNewState() {
        logger.logInfo("Changed to new state \(state)")

        switch state {
        case .searching:
            searchBackups()
        default:
            break
        }
        node.reloadData()
    }

    private func searchBackups() {
        logger.logInfo("Searching for backups in inbox")

        backupService.fetchBackups(for: user)
            .then(on: .main) { [weak self] keys in
                self?.proceedToSetupWith(keys: keys)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }

    private func handleOtherAccount() {
        router.signOut()
    }

    private func handle(error: Error) {
        handleCommon(error: error)
        state = .error(error)
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
            case .idle:
                return ASCellNode()
            case .searching:
                return self.searchStateNode(for: indexPath)
            case .error(let error):
                return self.errorStateNode(for: indexPath, error: error)
            case .noKeyBackups:
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
                self?.state = .searching
            }
        default:
            return ASCellNode()
        }
    }
}

// MARK: - Navigation
extension SetupInitialViewController {
    private func proceedToKeyImport() {
        let viewController = SetupImportKeyViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToCreatingNewKey() {
        let viewController = SetupKeyViewController(user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func proceedToSetupWith(keys: [KeyDetails]) {
        logger.logInfo("Finish searching for backups in inbox")

        if keys.isEmpty {
            logger.logInfo("No key backups found in inbox")
            state = .noKeyBackups
        } else {
            logger.logInfo("\(keys.count) key backups found in inbox")
            let viewController = SetupBackupsViewController(fetchedEncryptedKeys: keys, user: user)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
