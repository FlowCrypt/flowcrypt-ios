//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import GoogleSignIn
import UIKit

final class SignInViewController: UIViewController {
    // TODO: Inject as a dependency
    private let userService = UserService.shared

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
        GIDSignIn.sharedInstance()?.presentingViewController = self

        [signInWithGmailButton, signInWithOutlookButton].forEach {
            $0.bordered(color: .lightGray, width: 1).cornered(5.0)
        }

        privacyButton.do {
            $0.setTitle("sign_in_privacy".localized, for: .normal)
            $0.accessibilityLabel = "privacy"
        }

        termsButton.do {
            $0.setTitle("sign_in_terms".localized, for: .normal)
            $0.accessibilityLabel = "terms"
        }

        securityButton.do {
            $0.setTitle("sign_in_security".localized, for: .normal)
            $0.accessibilityLabel = "security"
        }

        gmailButton.do {
            $0.setTitle("sign_in_gmail".localized, for: .normal)
            $0.accessibilityLabel = "gmail"
        }

        outlookButton.do {
            $0.setTitle("sign_in_outlook".localized, for: .normal)
            $0.accessibilityLabel = "outlook"
        }

        descriptionText.do {
            $0.text = "sign_in_description".localized
            $0.accessibilityLabel = "description"
        }
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

    @IBAction func privacyPressed(_: Any) {
        guard let url = URL(string: "https://flowcrypt.com/privacy") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func termsPressed(_: Any) {
        guard let url = URL(string: "https://flowcrypt.com/license") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func securityPressed(_: Any) {
        guard let url = URL(string: "https://flowcrypt.com/docs/technical/security.html") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
