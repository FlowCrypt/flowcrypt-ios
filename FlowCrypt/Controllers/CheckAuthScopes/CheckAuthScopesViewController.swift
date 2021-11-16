//
//  CheckAuthScopesViewController.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 28.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

class CheckAuthScopesViewController: TableNodeViewController {
    private let missingScopes: [GoogleScope]
    private let globalRouter: GlobalRouterType

    init(
        missingScopes: [GoogleScope],
        globalRouter: GlobalRouterType = GlobalRouter()
    ) {
        self.missingScopes = missingScopes
        self.globalRouter = globalRouter
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

    var errorMessage: String {
        "gmail_service_no_access_to_account_message".localized
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension CheckAuthScopesViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return 3
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return self.unauthStateNode(for: indexPath)
        }
    }
}

// MARK: - UI
extension CheckAuthScopesViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self

        title = "FlowCrypt"
    }
    private func unauthStateNode(for indexPath: IndexPath) -> ASCellNode {
        switch indexPath.row {
        case 0:
            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: "setup_title"
                        .localized
                        .attributed(
                            .bold(35),
                            color: .mainTextColor,
                            alignment: .center
                        ),
                    insets: UIEdgeInsets(
                        top: 64, left: 16,
                        bottom: 64, right: 16
                    ),
                    backgroundColor: .backgroundColor
                )
            )
        case 1:
            return TextCellNode(
                input: .init(
                    backgroundColor: .backgroundColor,
                    title: errorMessage,
                    withSpinner: false,
                    size: CGSize(width: 200, height: 200),
                    alignment: .center
                )
            )
        case 2:
            return ButtonCellNode(input: .signInAgain) { [weak self] in
                guard let self = self else { return }
                self.globalRouter.signIn(with: .gmailLogin(self))
            }
        default:
            return ASCellNode()
        }
    }
}

private extension ButtonCellNode.Input {
    static var signInAgain: ButtonCellNode.Input {
        return .init(
            title: "continue"
                .localized
                .attributed(.bold(16), color: .white, alignment: .center),
            insets: UIEdgeInsets(top: 16, left: 24, bottom: 8, right: 24),
            color: .main
        )
    }
}
