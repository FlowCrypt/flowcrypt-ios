//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import RxSwift

final class SignInViewController: UIViewController {
    // TODO: Inject as a dependency
    private let userService = UserService.shared

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        signInWithGmailButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        signInWithOutlookButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        GIDSignIn.sharedInstance().uiDelegate = self

        userService.onLogin
            .observeOn(MainScheduler.instance)
            .take(1) // can be replaced based on navigation architecture
            .subscribe(onNext: { [weak self] _ in
                self?.performSegue(withIdentifier: "RecoverSegue", sender: nil)
            })
            .disposed(by: disposeBag)
        userService.onError
            .subscribe(onNext: { [weak self] error in
                self?.showAlert(error: error, message: "Failed to sign in")
            })
            .disposed(by: disposeBag)
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
