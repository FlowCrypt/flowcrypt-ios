//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import Promises

final class SignInViewController: UIViewController {
    // TODO: Inject as a dependency
    private let googleAPI = GoogleApi.instance

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        signInWithGmailButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        signInWithOutlookButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Events
    @IBAction func signInWithGmailButtonPressed(_ sender: Any) {
        showSpinner()
        googleAPI.signIn(viewController: self)
            .then(on: .main) { [weak self] _ in
                self?.hideSpinner()
                self?.performSegue(withIdentifier: "RecoverSegue", sender: nil)
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

}
