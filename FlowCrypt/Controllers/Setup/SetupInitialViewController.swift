//
//  SetupInitialViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 26.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

struct SetupInitialViewDecorator {
    let insets = SetupViewInsets()
}

// TODO: - ANTON
// - make intermediate screen to distinguish which flow to show (with backups/without backups)
// - searching will search keys
// - result will show createKey, importKey, anotherAccount
final class SetupInitialViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case title, createKey, importKey, anotherAccount
    }
    
    private enum State {
        case idle, searching, noKeyBackups
    }
    
    private var state = State.idle {
        didSet {
            node.reloadData()
        }
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        showSpinner()
        searchBackups()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        state = .searching
    }
    
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
    }
}

extension SetupInitialViewController {
    private func searchBackups() {
        logger.logInfo("[Setup] searching for backups in inbox")
        
        backupService.fetchBackups(for: user)
            .then(on: .main) { [weak self] keys in
                self?.proceedToSetupWith(keys: keys)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleCommon(error: error)
            }
    }
    
    private func handleOtherAccount() {
        router.signOut()
    }
    
    private func proceedToSetupWith(keys: [KeyDetails]) {
        logger.logInfo("Done searching for backups in inbox")
        
        let viewController: UIViewController
        if keys.isEmpty {
            logger.logInfo("No key backups found in inbox")
            state = .noKeyBackups
        } else {
            logger.logInfo("\(keys.count) key backups found in inbox")
            let viewController = SetupViewController(fetchedEncryptedKeys: keys, user: user)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension SetupInitialViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .idle, .searching:
            return 1
        case .noKeyBackups:
            return Parts.allCases.count
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            
            guard case .noKeyBackups = self.state else {
                // TODO: - ANTON return spinner node
                return ASCellNode()
            }
            
            guard let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.,
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .createKey:
                return ButtonCellNode(
                    title: self.decorator.buttonTitle,
                    insets: self.decorator.insets.buttonInsets
                ) { [weak self] in
                    
                }
            case .anotherAccount:
                return ButtonCellNode(
                    title: self.decorator.useAnotherAccountTitle,
                    insets: self.decorator.insets.optionalButtonInsets,
                    color: .white
                ) { [weak self] in
                    self?.handleOtherAccount()
                }
            case .importKey:
                
            }
        }
    }
}
