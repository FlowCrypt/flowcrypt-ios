//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import UIKit

/**
 * Sign in controller
 * - User can sign in with:
 * - Gmail
 * - Outlook (not implemented yet)
 * - Other email provider (*SetupImapViewController*)
 * - User can also check privacy, terms and security links via *WebViewController*
 */
final class SignInViewController: TableNodeViewController {

    enum AppLinks: String, CaseIterable {
        case privacy, terms, security
    }

    enum Parts: Int, CaseIterable {
        case links, logo, description, gmail
    }

    private let appContext: AppContext
    private let decorator: SignInViewDecoratorType

    init(
        appContext: AppContext,
        decorator: SignInViewDecoratorType = SignInViewDecorator()
    ) {
        self.appContext = appContext
        self.decorator = decorator

        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        node.view.separatorStyle = .none
        node.view.alwaysBounceVertical = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SignInViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let imageHeight = tableNode.bounds.size.height * 0.2
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .links:
                return LinkButtonNode(SignInViewController.AppLinks.allCases) { [weak self] identifier in
                    guard let appLink = AppLinks(rawValue: identifier) else { return }
                    self?.handle(option: appLink)
                }
            case .logo:
                return SignInImageNode(self.decorator.logo, imageHeight: imageHeight)
            case .description:
                return SignInDescriptionNode(self.decorator.description)
            case .gmail:
                return SigninButtonNode(.gmail) { [weak self] in
                    self?.signInWithGmail()
                }
            }
        }
    }
}

// MARK: - Events
extension SignInViewController {
    private func signInWithGmail() {
        Task {
            await appContext.globalRouter.signIn(
                appContext: appContext,
                route: .gmailLogin(self),
                email: nil
            )
        }
    }

    private func signInWithOutlook() {
        showToast("Outlook sign in not implemented yet")
    }

    private func proceedToOtherProvider() {
        let setupViewController = SetupImapViewController(appContext: appContext)
        navigationController?.pushViewController(setupViewController, animated: true)
    }

    private func handle(option: SignInViewController.AppLinks) {
        guard let url = option.url else { assertionFailure("Issue in provided url"); return }
        present(WebViewController(url: url), animated: true, completion: nil)
    }
}
