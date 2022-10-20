//
//  CheckMailAuthViewController.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 28.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import UIKit

class CheckMailAuthViewController: TableNodeViewController {
    private let appContext: AppContext
    private let decorator: CheckMailAuthViewDecorator
    private let email: String?

    init(appContext: AppContext, decorator: CheckMailAuthViewDecorator, email: String?) {
        self.appContext = appContext
        self.decorator = decorator
        self.email = email
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
}

// MARK: - ASTableDelegate, ASTableDataSource
extension CheckMailAuthViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return decorator.type.numberOfRows
    }

    func tableNode(_ node: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }
            return self.unauthStateNode(for: indexPath)
        }
    }
}

// MARK: - UI
extension CheckMailAuthViewController {
    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        node.bounces = false

        title = "app_name".localized
    }

    private func unauthStateNode(for indexPath: IndexPath) -> ASCellNode {
        switch indexPath.row {
        case 0:
            return SetupTitleNode(
                SetupTitleNode.Input(
                    title: decorator.title,
                    insets: .deviceSpecificTextInsets(top: 64, bottom: 64),
                    backgroundColor: .backgroundColor
                )
            )
        case 1:
            return TextCellNode(
                input: .init(
                    backgroundColor: .backgroundColor,
                    title: decorator.type.message,
                    withSpinner: false,
                    size: CGSize(width: 200, height: 200),
                    insets: .side(24),
                    textAlignment: .center
                )
            )
        case 2:
            return ButtonCellNode(input: .signInAgain) { [weak self] in
                self?.authorize()
            }
        case 3:
            return ButtonCellNode(input: .signOut) { [weak self] in
                self?.signOut()
            }
        default:
            return ASCellNode()
        }
    }

    private func authorize() {
        Task {
            await self.appContext.globalRouter.signIn(
                appContext: self.appContext,
                route: .gmailLogin(self),
                email: email
            )
        }
    }

    private func signOut() {
        Task {
            do {
                try await appContext.globalRouter.signOut(appContext: appContext)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }
}

private extension ButtonCellNode.Input {
    static var signInAgain: ButtonCellNode.Input {
        return .init(
            title: "continue"
                .localized
                .attributed(.bold(16), color: .white, alignment: .center),
            color: .main
        )
    }

    static var signOut: ButtonCellNode.Input {
        return .init(
            title: "log_out"
                .localized
                .attributed(.bold(16), color: .white, alignment: .center),
            color: .red
        )
    }
}
