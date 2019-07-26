//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

class RecoverViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var passPhaseTextField: UITextField!
    var encryptedBackups = [KeyDetails]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchMessage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func validatePassPhase() {
        let entered_pass_phrase = self.passPhaseTextField.text!
        Promise<Void> { () -> Void in
            var matching = [KeyDetails]()
            for k in self.encryptedBackups {
                let decryptRes = try Core.decryptKey(armoredPrv: k.private!, passphrase: entered_pass_phrase)
                if decryptRes.decryptedKey != nil {
                    matching.append(k)
                }
            }
            guard matching.count == 0 else {
                return self.showErrAlert(Language.wrong_pass_phrase_retry, onOk: { self.passPhaseTextField.becomeFirstResponder() })
            }
            let realm = try! Realm()
            try! realm.write {
                for k in matching {
                    realm.add(KeyInfo(k, passphrase: entered_pass_phrase, source: "backup"))    
                }
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "InboxSegue", sender: nil)
            }
        }.catch { error in
            self.showErrAlert("\(Language.unhandled_core_err)\n\n\(error)", onOk: nil)
        }
    }

    func searchMessage() {
        self.showSpinner()
        Promise<Void> { _,_ in
            self.hideSpinner()
            let armoredBackups = try await(Imap.instance.searchBackups(email: GoogleApi.instance.getEmail()))
            let keyDetailsRes = try Core.parseKeys(armoredOrBinary: armoredBackups.joined(separator: "\n").data(using: .utf8) ?? Data())
            self.encryptedBackups = keyDetailsRes.keyDetails.filter { $0.private != nil }
            if self.encryptedBackups.count == 0 {
                let alert = UIAlertController(title: "Notice", message: Language.no_backups, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in self.searchMessage() })
                alert.addAction(UIAlertAction(title: Language.use_other_account, style: .default) { _ in
                    GoogleApi.instance.signOut().then(on: .main) { _ in
                        // todo - go to sign in activity
                    }.catch { error in self.showErrAlert("\(Language.action_failed)\n\n\(error)", onOk: nil)}
                })
            }
        }.catch { error in self.showErrAlert("\(Language.action_failed)\n\n\(error)", onOk: nil) }
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
