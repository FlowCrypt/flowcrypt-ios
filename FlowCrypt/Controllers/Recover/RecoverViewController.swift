//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

final class RecoverViewController: UIViewController {
    private enum Constants {
        static let noBackups = "No backups found on account: \n"
        static let actionFailed = "Action failed"
        static let useOtherAccount = "Use other account"
        static let enterPassPhrase = "Enter pass phrase"
        static let wrongPassPhraseRetry = "Wrong pass phrase, please try again"
    }
    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private let userService = UserService.shared
    private let router = GlobalRouter()

    @IBOutlet weak var passPhaseTextField: UITextField!
    @IBOutlet weak var btnLoadAccount: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!

    private var encryptedBackups: [KeyDetails] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchBackups()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnLoadAccount.layer.cornerRadius = 5
    }
}

extension RecoverViewController {
    private func observeKeyboardNotifications() {
        _ = keyboardHeight
            .map { UIEdgeInsets(top: 0, left: 0, bottom: $0 + 5, right: 0) }
            .subscribe(onNext: { [weak self] inset in
                self?.scrollView.contentInset = inset
                self?.scrollView.scrollIndicatorInsets = inset
            })
    }

    private func setupUI() {
        UITapGestureRecognizer(target: self, action: #selector(endEditing)).do {
            $0.cancelsTouchesInView = false
            self.view.addGestureRecognizer($0)
        }
        passPhaseTextField.delegate = self
        observeKeyboardNotifications()
    }

    private func fetchBackups() {
        showSpinner()
        Promise<Void> { [weak self] in
            guard let self = self else { return }
            guard let email = DataManager.shared.currentUser()?.email else { throw AppErr.unexpected("Missing account email") }
            let backupData = try await(self.imap.searchBackups(email: email))
            let parsed = try Core.parseKeys(armoredOrBinary: backupData)
            self.encryptedBackups = parsed.keyDetails.filter { $0.private != nil }
        }.then(on: .main) {
            self.hideSpinner()
            if self.encryptedBackups.isEmpty {
                self.showRetryFetchBackupsOrChangeAcctAlert(msg: Constants.noBackups + (DataManager.shared.currentUser()?.email ?? "(unknown)"))
            }
        }.catch(on: .main) { [weak self] error in
            self?.showRetryFetchBackupsOrChangeAcctAlert(msg: "\(Constants.actionFailed)\n\n\(error)")
        }
    }

    private func showRetryFetchBackupsOrChangeAcctAlert(msg: String) {
        let alert = UIAlertController(title: "Notice", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.fetchBackups()
        })
        alert.addAction(UIAlertAction(title: Constants.useOtherAccount, style: .default) { [weak self] _ in
            self?.userService.signOut().then(on: .main) { [weak self] in
                if self?.navigationController?.popViewController(animated: true) == nil {
                    self?.router.proceedAfterLogOut() // in case app got restarted and no view to pop
                }
            }.catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Could not sign out")
            }
        })
        present(alert, animated: true, completion: nil)
    }

}

extension RecoverViewController {
    @objc private func endEditing() {
        view.endEditing(true)
    }

    @IBAction func loadAccountButtonPressed(_ sender: Any) {
        endEditing()
        guard let passPhrase = passPhaseTextField.text, !passPhrase.isEmpty else {
            showAlert(message: Constants.enterPassPhrase)
            return
        }
        showSpinner()
        let matchingBackups: [KeyDetails] = encryptedBackups
            .compactMap { (key) -> KeyDetails? in
                guard let prv = key.private else { return nil }
                guard let r = try? Core.decryptKey(armoredPrv: prv, passphrase: passPhrase), r.decryptedKey != nil else { return nil }
                return key
            }

        guard matchingBackups.count > 0 else {
            showAlert(message: Constants.wrongPassPhraseRetry)
            return
        }
        // TODO: - Refactor with realm service
        let realm = try! Realm()
        try! realm.write {
            for k in matchingBackups {
                realm.add(try! KeyInfo(k, passphrase: passPhrase, source: .backup))
            }
        }
        moveToMainFlow()
    }

    private func moveToMainFlow() {
        GlobalRouter().proceedAfterLogOut()
    }

    @IBAction func useOtherAccount(_ sender: Any) {
        userService.signOut().then(on: .main) { [weak self] _ in
            self?.router.proceedAfterLogOut()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not switch accounts")
        }
    }
}

extension RecoverViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
