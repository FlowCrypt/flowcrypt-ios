//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

class RecoverViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var passPhaseTextField: UITextField!
    var encryptedBackups: [KeyDetails]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchBackups()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func fetchBackups() {
        self.showSpinner()
        self.async({ () -> [KeyDetails] in
            let armoredBackupsData = try await(Imap.instance.searchBackups(email: GoogleApi.instance.getEmail()))
            let keyDetailsRes = try Core.parseKeys(armoredOrBinary: armoredBackupsData)
            return keyDetailsRes.keyDetails
        }, then: { keyDetails in
            self.hideSpinner()
            self.encryptedBackups = keyDetails.filter { $0.private != nil }
            if self.encryptedBackups!.count == 0 {
                let alert = UIAlertController(title: "Notice", message: Language.no_backups, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in self.fetchBackups() })
                alert.addAction(UIAlertAction(title: Language.use_other_account, style: .default) { _ in
                    self.async({ GoogleApi.instance.signOut() }, then: { _ in
                        let signInVc = self.instantiate(viewController: SignInViewController.self)
                        self.navigationController?.pushViewController(signInVc, animated: true)
                    })
                })
                self.present(alert, animated: true, completion: nil)
            }
        })
    }

    @IBAction func loadAccountButtonPressed(_ sender: Any) {
        let entered_pass_phrase = self.passPhaseTextField.text!
        if entered_pass_phrase.isEmpty {
            self.showErrAlert(Language.enter_pass_phrase) { self.passPhaseTextField.becomeFirstResponder() }
            return
        }
        self.showSpinner()
        self.async({ () -> [KeyDetails] in
            var matchingBackups = [KeyDetails]()
            for k in self.encryptedBackups! {
                let decryptRes = try Core.decryptKey(armoredPrv: k.private!, passphrase: entered_pass_phrase)
                if decryptRes.decryptedKey != nil {
                    matchingBackups.append(k)
                }
            }
            return matchingBackups
        }, then: { matchingBackups in
            guard matchingBackups.count > 0 else {
                self.showErrAlert(Language.wrong_pass_phrase_retry) { self.passPhaseTextField.becomeFirstResponder() }
                return
            }
            let realm = try! Realm()
            try! realm.write {
                for k in matchingBackups {
                    realm.add(KeyInfo(k, passphrase: entered_pass_phrase, source: "backup"))
                }
            }
            self.performSegue(withIdentifier: "InboxSegue", sender: nil)
        })
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

}
