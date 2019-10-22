//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import GoogleSignIn
import UIKit
import AsyncDisplayKit

final class SignInViewController: ASViewController<ASTableNode> {
    enum Parts: Int, CaseIterable {
        case options, logo, description, gmail, outlook
    }

    private let userService: UserServiceType

    init(userService: UserServiceType = UserService.shared) {
        self.userService = userService
        super.init(node: ASTableNode() )
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var securityButton: UIButton!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var gmailButton: UIButton!
    @IBOutlet weak var outlookButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
//        GIDSignIn.sharedInstance()?.presentingViewController = self
//
//        [signInWithGmailButton, signInWithOutlookButton].forEach {
//            $0.bordered(color: .lightGray, width: 1).cornered(5.0)
//        }
//
//
//
//        gmailButton.do {
//            $0.setTitle("sign_in_gmail".localized, for: .normal)
//            $0.accessibilityLabel = "gmail"
//        }
//
//        outlookButton.do {
//            $0.setTitle("sign_in_outlook".localized, for: .normal)
//            $0.accessibilityLabel = "outlook"
//        }
//
//        descriptionText.do {
//            $0.text = "sign_in_description".localized
//            $0.accessibilityLabel = "description"
//        }
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

// MARK: - Events

extension SignInViewController {
    @IBAction func signInWithGmailButtonPressed(_: Any) {
        logDebug(106, "GoogleApi.signIn")
        userService.signIn()
            .then(on: .main) { [weak self] _ in
                self?.performSegue(withIdentifier: "RecoverSegue", sender: nil)
            }
            .catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Failed to sign in")
            }
    }

    @IBAction func signInWithOutlookButtonPressed(_: Any) {
        showToast("Outlook sign in not implemented yet")
        // below for debugging
        do {
            let start = DispatchTime.now()
            //            let decrypted = try Core.decryptKey(armoredPrv: TestData.k3rsa4096.prv, passphrase: TestData.k3rsa4096.passphrase)
            let keys = [PrvKeyInfo(private: TestData.k3rsa4096.prv, longid: TestData.k3rsa4096.longid, passphrase: TestData.k3rsa4096.passphrase)]

            guard let encrypted = TestData.matchingEncryptedMsg.data(using: .utf8) else {
                assertionFailure(); return
            }

            let decrypted = try Core.parseDecryptMsg(
                encrypted: encrypted,
                keys: keys,
                msgPwd: nil,
                isEmail: false
            )
            print(decrypted)
            print("decrypted \(start.millisecondsSince)")
            //            print("text: \(decrypted.text)")
        } catch CoreError.exception {
            print("catch exception")
            //            print(msg)
        } catch {
            print("catch generic")
            print(error)
        }
    }
}

extension SignInViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 1
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .options:
                return OptionButtonNode(inputs: OptionsButton.allCases) { [weak self] action in
                    self?.handle(option: action)
                }
            case .logo: return ASCellNode()
            case .description: return ASCellNode()
            case .gmail: return ASCellNode()
            case .outlook: return ASCellNode()
            }
        }
    }

    private func handle(option: OptionsButton) {
        guard let url = option.url else { assertionFailure("Issue in provided url"); return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

final class OptionButtonNode: ASCellNode {
    typealias Action = (OptionsButton) -> ()

    private let buttons: [ASButtonNode]
    private var tapAction: Action?

    init(inputs: [OptionsButton], action: Action?) {
        tapAction = action
        buttons = inputs.map {
            let button = ASButtonNode()
            button.setAttributedTitle($0.attributedTitle, for: .normal)
            button.accessibilityLabel = $0.rawValue
            return button
        }
        super.init()
        automaticallyManagesSubnodes = true
        buttons.forEach { $0.addTarget(self, action: #selector(onTap(_:)), forControlEvents: .touchUpInside) }
    }

    @objc private func onTap(_ sender: ASButtonNode) {
        guard let identifier = sender.accessibilityLabel, let button = OptionsButton(rawValue: identifier) else { return }
        tapAction?(button)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: ASStackLayoutSpec(
                    direction: .horizontal,
                    spacing: 16,
                    justifyContent: .center,
                    alignItems: .center,
                    children: buttons
                )
            )
        )
    }
}



