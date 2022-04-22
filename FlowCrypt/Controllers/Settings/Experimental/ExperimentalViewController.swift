//
//  ExperimentalViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/22/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * ExperimentalViewController
 * - Shows list of experimental views
 * - User can be redirected here from Settings View
 * - Tap on each row will navigate user to appropriate experimental controller
 */
final class ExperimentalViewController: TableNodeViewController {
    private enum ExperimentalMenuItem: Int, CaseIterable {
        case reloadApp

        var title: String {
            switch self {
            case .reloadApp: return "experimental_reload_app".localized
            }
        }
    }

    private let appContext: AppContextWithUser
    private let decorator: ExperimentalViewDecorator
    private let rows: [ExperimentalMenuItem]

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        appContext: AppContextWithUser,
        decorator: ExperimentalViewDecorator = ExperimentalViewDecorator()
    ) {
        self.appContext = appContext
        self.decorator = decorator
        self.rows = ExperimentalMenuItem.allCases
        super.init(node: TableNode())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ExperimentalViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        rows.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            let setting = self.rows[indexPath.row]
            return TitleCellNode(
                title: self.decorator.attributedSetting(setting.title),
                insets: self.decorator.insets
            )
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let setting = rows[indexPath.row]

        Task {
            try await proceed(to: setting)
        }
    }
}

// MARK: - Actions

extension ExperimentalViewController {
    private func proceed(to setting: ExperimentalMenuItem) async throws {
        switch setting {
        case .reloadApp:
            try reloadApp()
        }
    }

    private func reloadApp() throws {
        try appContext.passPhraseService.removeInMemoryPassPhrases(for: appContext.user.email)
        GlobalRouter().proceed()
    }
}
