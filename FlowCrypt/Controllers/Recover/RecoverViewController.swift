//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

class RecoverViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var passPhaseTextField: UITextField!
    var rawArmoredKey: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchMessage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func validatePassPhase() {
        let entered_pass_phrase = self.passPhaseTextField.text!
        Promise<Void> { () -> Void in
            let keyDetailsRes = try Core.parseKeys(armoredOrBinary: self.rawArmoredKey.data(using: .utf8) ?? Data())
            guard keyDetailsRes.keyDetails.count > 0 else {
                return self.showErrAlert(Language.no_backups)
            }
            let keyDetails = keyDetailsRes.keyDetails[0]
            guard keyDetails.private != nil else {
                return self.showErrAlert(Language.no_backups)
            }
            let decryptRes = try Core.decryptKey(armoredPrv: keyDetails.private!, passphrase: entered_pass_phrase)
            guard decryptRes.decryptedKey != nil else {
                return self.showErrAlert(Language.wrong_pass_phrase_retry, onOk: { self.passPhaseTextField.becomeFirstResponder() })
            }
            let realm = try! Realm()
            try! realm.write {
                realm.add(KeyInfo(keyDetails, passphrase: entered_pass_phrase, source: "backup"))
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "InboxSegue", sender: nil)
            }
        }.catch { error in
            self.showErrAlert("\(Language.unhandled_core_err)\n\n\(error)", onOk: nil)
        }
    }

    func searchMessage() {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading"
        spinnerActivity.isUserInteractionEnabled = false
        EmailProvider.sharedInstance.searchBackup(email: GoogleApi.instance.getEmail()) { (rawArmoredKey: String?, error: Error?) in
            spinnerActivity.hide(animated: true)
            if rawArmoredKey != nil {
                self.rawArmoredKey = rawArmoredKey!
            } else {
                let alert = UIAlertController(title: "Notice", message: Language.no_backups, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { action in
                    self.searchMessage()
                })
                alert.addAction(UIAlertAction(title: Language.use_other_account, style: .default) { action in
                    GoogleApi.instance.signOut({ (error: Error?) in
                        if error != nil {
                            let alert = UIAlertController(title: "Error", message: Language.no_internet, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { action in
                                self.passPhaseTextField.becomeFirstResponder()
                            })
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
                })
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func loadAccountButtonPressed(_ sender: Any) {
        if self.passPhaseTextField.text!.isEmpty {
            let alert = UIAlertController(title: "Notice", message: Language.enter_pass_phrase, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { action in
                self.passPhaseTextField.becomeFirstResponder()
            })
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.validatePassPhase()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

}
