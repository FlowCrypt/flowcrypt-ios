//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import GoogleSignIn
import UIKit
import AsyncDisplayKit
import FlowCryptUI
import FlowCryptCommon

final class SignInViewController: ASViewController<ASTableNode> {
    enum Parts: Int, CaseIterable {
        case links, logo, description, gmail, other
    }

    private let userService: UserServiceType
    private let core: Core
    private let decorator: SignInViewDecoratorType

    init(
        userService: UserServiceType = UserService.shared,
        core: Core = Core.shared,
        decorator: SignInViewDecoratorType = SignInViewDecorator()
    ) {
        self.core = core
        self.userService = userService
        self.decorator = decorator

        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }

    private func setup() {
        GIDSignIn.sharedInstance()?.presentingViewController = self
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        node.reloadData()
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SignInViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let imageHeight = tableNode.bounds.size.height * 0.2

        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .links:
                return LinkButtonNode(AppLinks.allCases) { [weak self] identifier in
                    guard let appLink = AppLinks(rawValue: identifier) else { return }
                    self?.handle(option: appLink)
                }
            case .logo:
                return SignInImageNode(self.decorator.logo, height: imageHeight)
            case .description:
                return SignInDescriptionNode(self.decorator.description)
            case .gmail:
                return SigninButtonNode(.gmail) { [weak self] in
                    self?.signInWithGmail()
                }
            case .other:
                return SigninButtonNode(.other) { [weak self] in
                    self?.proceedToOtherProvider()
                }
            }
        }
    }
}

// MARK: - Events

extension SignInViewController {
    private func signInWithGmail() {
        logDebug(106, "GoogleApi.signIn")
        userService.signIn()
            .then(on: .main) { [weak self] _ in
                self?.proceedToRecover()
            }
            .catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Failed to sign in")
            }
    }

    private func proceedToRecover() {
        let setupViewController = SetupViewController()
        navigationController?.pushViewController(setupViewController, animated: true)
    }

    private func proceedToOtherProvider() {
        let setupViewController = EmailProviderViewController()
        navigationController?.pushViewController(setupViewController, animated: true)
    }

    private func handle(option: AppLinks) {
        guard let url = option.url else { assertionFailure("Issue in provided url"); return }
        if #available(iOS 13.0, *) {
            present(WebViewController(url: url), animated: true, completion: nil)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
