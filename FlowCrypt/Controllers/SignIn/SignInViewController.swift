//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn

final class SignInViewController: UIViewController {
    // TODO: Inject as a dependency
    private let userService = UserService.shared

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        signInWithGmailButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        signInWithOutlookButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        GIDSignIn.sharedInstance().uiDelegate = self
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
    @IBAction func signInWithGmailButtonPressed(_ sender: Any) {
        logDebug(106, "GoogleApi.signIn")
        userService.signIn()
            .then(on: .main) { [weak self] _ in
                self?.performSegue(withIdentifier: "RecoverSegue", sender: nil)
            }
            .catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Failed to sign in")
            }
    }

    @IBAction func signInWithOutlookButtonPressed(_ sender: Any) {
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

    @IBAction func privacyPressed(_ sender: Any) {
        guard let url = URL(string: "https://flowcrypt.com/privacy") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func termsPressed(_ sender: Any) {
        guard let url = URL(string: "https://flowcrypt.com/license") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func securityPressed(_ sender: Any) {
        guard let url = URL(string: "https://flowcrypt.com/docs/technical/security.html") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }


}

extension SignInViewController: GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        logDebug(117, "GoogleApi present vc")
        present(viewController, animated: true, completion: nil)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        logDebug(118, "GoogleApi dismiss vc")
        dismiss(animated: true, completion: nil)
    }
}
