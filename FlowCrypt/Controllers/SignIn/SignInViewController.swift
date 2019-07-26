//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn

class SignInViewController: BaseViewController {

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.signInWithGmailButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        self.signInWithOutlookButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    // MARK: - Events
    @IBAction func signInWithGmailButtonPressed(_ sender: Any) {
        GoogleApi.instance.signIn(viewController: self)
            .then(on: .main) { user in self.performSegue(withIdentifier: "RecoverSegue", sender: nil) }
            .catch { error in self.showErrAlert(String(describing: error))
        }
    }

    @IBAction func signInWithOutlookButtonPressed(_ sender: Any) {
        do {
            let start = DispatchTime.now()
            let keys = [PrvKeyInfo(private: TestData.k2rsa2048.prv, longid: TestData.k2rsa2048.longid, passphrase: TestData.k2rsa2048.passphrase)]
            let decrypted = try Core.parseDecryptMsg(encrypted: TestData.matchingEncryptedMsg.data(using: .utf8)!, keys: keys, msgPwd: nil, isEmail: false)
            print("decrypted \(start.millisecondsSince())")
            print(decrypted)
            print("text: \(decrypted.text)")
        } catch Core.Error.exception {
            print("catch exception")
//            print(msg)
        } catch {
            print("catch generic")
            print(error)
        }

    }

}
