//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import GoogleSignIn
import UIKit

final class SignInViewController: ASViewController<TableNode> {
    enum Parts: Int, CaseIterable {
        case links, logo, description, gmail, outlook, other
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

    required init?(coder _: NSCoder) {
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
            case .outlook:
                return SigninButtonNode(.outlook) { [weak self] in
                    self?.signInWithOutlook()
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

    private func signInWithOutlook() {
        showToast("Outlook sign in not implemented yet")
        // below for debugging
        do {
            let start = DispatchTime.now()
            //            let decrypted = try Core.decryptKey(armoredPrv: TestData.k3rsa4096.prv, passphrase: TestData.k3rsa4096.passphrase)
            let keys = [
                PrvKeyInfo(
                    private: TestData.k3rsa4096.prv,
                    longid: TestData.k3rsa4096.longid,
                    passphrase: TestData.k3rsa4096.passphrase
                )
            ]

            guard let encrypted = TestData.matchingEncryptedMsg.data(using: .utf8) else {
                assertionFailure(); return
            }

            let decrypted = try core.parseDecryptMsg(
                encrypted: encrypted,
                keys: keys,
                msgPwd: nil,
                isEmail: false
            )
            debugPrint(decrypted)
            debugPrint("decrypted \(start.millisecondsSince)")
            //            debugPrint("text: \(decrypted.text)")
        } catch CoreError.exception {
            debugPrint("catch exception")
            //            debugPrint(msg)
        } catch {
            debugPrint("catch generic")
            debugPrint(error)
        }

    }

    private func proceedToRecover() {
        GlobalRouter().proceed()
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
