//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

final class SetupViewController: UIViewController {

    private enum Constants {
        static let noBackups = "No backups found on account: \n"
        static let actionFailed = "Action failed"
        static let useOtherAccount = "Use other account"
        static let enterPassPhrase = "Enter pass phrase"
        static let wrongPassPhraseRetry = "Wrong pass phrase, please try again"
    }

    private enum SetupAction {
        case recoverKey
        case createKey
    }

    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private let userService = UserService.shared
    private let router = GlobalRouter()
    private var setupAction = SetupAction.recoverKey

    @IBOutlet weak var passPhaseTextField: UITextField!
    @IBOutlet weak var btnLoadAccount: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    private var fetchedEncryptedPrvs: [KeyDetails] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchBackupsAndRenderSetupView()
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

extension SetupViewController {

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

    private func fetchBackupsAndRenderSetupView() {
        showSpinner()
        Promise<Void> { [weak self] in
            guard let self = self else { return }
            guard let email = DataManager.shared.currentUser()?.email else { throw AppErr.unexpected("Missing account email") }
            let backupData = try await(self.imap.searchBackups(email: email))
            let parsed = try Core.parseKeys(armoredOrBinary: backupData)
            self.fetchedEncryptedPrvs = parsed.keyDetails.filter { $0.private != nil }
        }.then(on: .main) { [weak self] in
            guard let self = self else { return }
            self.hideSpinner()
            if self.fetchedEncryptedPrvs.isEmpty {
                self.renderNoBackupsFoundOptions(msg: Constants.noBackups + (DataManager.shared.currentUser()?.email ?? "(unknown)"))
            } else {
                self.subTitleLabel.text = "Found \(self.fetchedEncryptedPrvs.count) key backup\(self.fetchedEncryptedPrvs.count > 1 ? "s" : "")"
            }
        }.catch(on: .main) { [weak self] error in
            self?.renderNoBackupsFoundOptions(msg: Constants.actionFailed, error: error)
        }
    }

    private func renderNoBackupsFoundOptions(msg: String, error: Error? = nil) {
        let errStr = error != nil ? "\n\n\(error!)" : ""
        let alert = UIAlertController(title: "Notice", message: msg + errStr, preferredStyle: .alert)
        if error == nil { // no backous found, not an error: show option to create a key or import key
            alert.addAction(UIAlertAction(title: "Import existing Private Key", style: .default) { [weak self] _ in
                self?.showToast("Key Import will be implemented soon! Contact human@flowcrypt.com")
                self?.renderNoBackupsFoundOptions(msg: msg, error: nil)
            })
            alert.addAction(UIAlertAction(title: "Create new Private Key", style: .default) { [weak self] _ in
                self?.subTitleLabel.text = "Create a new OpenPGP Private Key"
                self?.btnLoadAccount.setTitle("Create Key", for: .normal)
                self?.setupAction = SetupAction.createKey
                // todo - show strength bar while typed so that user can choose the strength they need
            })
        }
        alert.addAction(UIAlertAction(title: Constants.useOtherAccount, style: .default) { [weak self] _ in
            self?.userService.signOut().then(on: .main) { [weak self] in
                if self?.navigationController?.popViewController(animated: true) == nil {
                    self?.router.proceedAfterLogOut() // in case app got restarted and no view to pop
                }
            }.catch(on: .main) { [weak self] error in
                self?.showAlert(error: error, message: "Could not sign out")
            }
        })
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.fetchBackupsAndRenderSetupView()
        })
        present(alert, animated: true, completion: nil)
    }

}

extension SetupViewController {

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
        if setupAction == SetupAction.recoverKey {
            recoverAccountWithBackups(with: passPhrase)
        } else if setupAction == SetupAction.createKey {
            setupAccountWithGeneratedKey(with: passPhrase)
        } else {
            showAlert(message: "Unknown setupAction \(setupAction), please contact human@flowcrypt.com")
        }
    }

    private func recoverAccountWithBackups(with passPhrase: String) {
        let matchingBackups: [KeyDetails] = fetchedEncryptedPrvs
            .compactMap { (key) -> KeyDetails? in
                guard let prv = key.private else { return nil }
                guard let r = try? Core.decryptKey(armoredPrv: prv, passphrase: passPhrase), r.decryptedKey != nil else { return nil }
                return key
            }
        guard matchingBackups.count > 0 else {
            showAlert(message: Constants.wrongPassPhraseRetry)
            return
        }
        try! self.storePrvs(prvs: matchingBackups, passPhrase: passPhrase, source: .generated)
        performSegue(withIdentifier: "InboxSegue", sender: nil)
    }

    private func setupAccountWithGeneratedKey(with passPhrase: String) {
        Promise { [weak self] in
            guard let self = self else { return }
            let userId = try self.getUserId()
            try await(self.validateAndConfirmNewPassPhraseOrReject(passPhrase: passPhrase))
            let encryptedPrv = try Core.generateKey(passphrase: passPhrase, variant: .curve25519, userIds: [userId])
            try await(self.backupPrvToInbox(prv: encryptedPrv.key, userId: userId))
            try self.storePrvs(prvs: [encryptedPrv.key], passPhrase: passPhrase, source: .generated)
            try await(self.alertAndSkipOnRejection(AttesterApi.shared.updateKey(email: userId.email, pubkey: encryptedPrv.key.public), fail: "Failed to submit Public Key"))
            try await(self.alertAndSkipOnRejection(AttesterApi.shared.testWelcome(email: userId.email, pubkey: encryptedPrv.key.public), fail: "Failed to send you welcome email"))
        }.then(on: .main) { [weak self] in
            self?.performSegue(withIdentifier: "InboxSegue", sender: nil)
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not finish setup, please try again")
        }
    }

    private func validateAndConfirmNewPassPhraseOrReject(passPhrase: String) -> Promise<Void> {
        return Promise {
            let strength = try Core.zxcvbnStrengthBar(passPhrase: passPhrase)
            guard strength.word.pass else { throw AppErr.user("Pass phrase strength: \(strength.word.word)\ncrack time: \(strength.time)\n\nWe recommend to use 5-6 unrelated words as your Pass Phrase.") }
            let confirmPassPhrase = try await(self.awaitUserPassPhraseEntry(title: "Confirm Pass Phrase"))
            guard confirmPassPhrase != nil else { throw AppErr.silentAbort }
            guard confirmPassPhrase == passPhrase else { throw AppErr.user("Pass phrases don't match") }
        }
    }

    private func getUserId() throws -> UserId {
        guard let email = DataManager.shared.currentUser()?.email, !email.isEmpty else { throw AppErr.unexpected("Missing user email") }
        guard let name = DataManager.shared.currentUser()?.name, !name.isEmpty else { throw AppErr.unexpected("Missing user name") }
        return UserId(email: email, name: name)
    }

    private func backupPrvToInbox(prv: KeyDetails, userId: UserId) -> Promise<Void> {
        return Promise { () -> Void in
            guard prv.isFullyEncrypted ?? false else { throw AppErr.unexpected("Private Key must be fully enrypted before backing up") }
            let filename = "flowcrypt-backup-\(userId.email.replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)).key"
            let backupEmail = try Core.composeEmail(msg: SendableMsg(
                text: "This email contains a key backup. It will help you access your encrypted messages from other computers (along with your pass phrase). You can safely leave it in your inbox or archive it.\n\nThe key below is protected with pass phrase that only you know. You should make sure to note your pass phrase down.\n\nDO NOT DELETE THIS EMAIL. Write us at human@flowcrypt.com so that we can help.",
                to: [userId.toMime()],
                cc: [],
                bcc: [],
                from: userId.toMime(),
                subject: "Your FlowCrypt Backup",
                replyToMimeMsg: nil,
                atts: [SendableMsg.Att(name: filename, type: "text/plain", base64: prv.private!.data().base64EncodedString())] // !crash ok
            ), fmt: .plain, pubKeys: nil)
            try await(Imap.instance.sendMail(mime: backupEmail.mimeEncoded))
        }
    }

    private func storePrvs(prvs: [KeyDetails], passPhrase: String, source: KeySource) throws {
        let realm = try! Realm() // TODO: - Refactor with realm service
        try! realm.write {
            for k in prvs {
                realm.add(try! KeyInfo(k, passphrase: passPhrase, source: source))
            }
        }
    }

    @IBAction func useOtherAccount(_ sender: Any) {
        userService.signOut().then(on: .main) { [weak self] _ in
            self?.router.proceedAfterLogOut()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not switch accounts")
        }
    }

}

extension SetupViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

}
