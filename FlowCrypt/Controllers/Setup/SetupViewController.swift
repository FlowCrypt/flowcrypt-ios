//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import MBProgressHUD
import Promises
import RealmSwift
import UIKit
import AsyncDisplayKit

final class SetupViewController: ASViewController<ASTableNode> {
    private enum Parts: Int, CaseIterable {
        case title, passPrase, description, action, optionalAction
    }

    private enum SetupAction {
        case recoverKey
        case createKey
    }

    private let imap: Imap
    private let userService: UserServiceType
    private let router: GlobalRouterType

    private var setupAction = SetupAction.recoverKey
    private var fetchedEncryptedPrvs: [KeyDetails] = []

    init(
        imap: Imap = .instance,
        userService: UserServiceType = UserService.shared,
        router: GlobalRouterType = GlobalRouter()
    ) {
        self.imap = imap
        self.userService = userService
        self.router = router

        super.init(node: ASTableNode())
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchBackupsAndRenderSetupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

extension SetupViewController {
    private func setupUI() {
        node.view.showsVerticalScrollIndicator = false
        observeKeyboardNotifications()

        //        btnLoadAccount.setTitle("setup_load".localized, for: .normal)
        //        btnUseAnother.setTitle("setup_use_another".localized, for: .normal)
        //        subTitleLabel.text = "setup_description".localized
    }

    private func observeKeyboardNotifications() {
        _ = keyboardHeight
            .map { UIEdgeInsets(top: 0, left: 0, bottom: $0 + 5, right: 0) }
            .subscribe(onNext: { [weak self] inset in
                self?.node.contentInset = inset
                self?.node.scrollToRow(at: IndexPath(item: Parts.passPrase.rawValue, section: 0), at: .middle, animated: true)
            })
    }

    private func fetchBackupsAndRenderSetupView() {
        //        showSpinner()
        //        Promise<Void> { [weak self] in
        //            guard let self = self else { return }
        //            let backupData = try await(self.imap.searchBackups())
        //            let parsed = try Core.parseKeys(armoredOrBinary: backupData)
        //            self.fetchedEncryptedPrvs = parsed.keyDetails.filter { $0.private != nil }
        //        }.then(on: .main) { [weak self] in
        //            guard let self = self else { return }
        //            self.hideSpinner()
        //            if self.fetchedEncryptedPrvs.isEmpty {
        //                let msg = "setup_no_backups".localized
        //                self.renderNoBackupsFoundOptions(msg: msg + (DataManager.shared.currentUser()?.email ?? "(unknown)"))
        //            } else {
        //                self.subTitleLabel.text = "Found \(self.fetchedEncryptedPrvs.count) key backup\(self.fetchedEncryptedPrvs.count > 1 ? "s" : "")"
        //            }
        //        }.catch(on: .main) { [weak self] error in
        //            self?.renderNoBackupsFoundOptions(msg: "setup_action_failed".localized, error: error)
        //        }
    }

    private func renderNoBackupsFoundOptions(msg: String, error: Error? = nil) {
        //        let errStr = error != nil ? "\n\n\(error!)" : ""
        //        let alert = UIAlertController(title: "Notice", message: msg + errStr, preferredStyle: .alert)
        //        if error == nil { // no backous found, not an error: show option to create a key or import key
        //            alert.addAction(UIAlertAction(title: "Import existing Private Key", style: .default) { [weak self] _ in
        //                self?.showToast("Key Import will be implemented soon! Contact human@flowcrypt.com")
        //                self?.renderNoBackupsFoundOptions(msg: msg, error: nil)
        //            })
        //            alert.addAction(UIAlertAction(title: "Create new Private Key", style: .default) { [weak self] _ in
        //                self?.subTitleLabel.text = "Create a new OpenPGP Private Key"
        //                self?.btnLoadAccount.setTitle("Create Key", for: .normal)
        //                self?.setupAction = SetupAction.createKey
        //                // todo - show strength bar while typed so that user can choose the strength they need
        //            })
        //        }
        //        alert.addAction(UIAlertAction(title: "setup_use_otherAccount".localized, style: .default) { [weak self] _ in
        //            self?.userService.signOut().then(on: .main) { [weak self] in
        //                if self?.navigationController?.popViewController(animated: true) == nil {
        //                    self?.router.reset() // in case app got restarted and no view to pop
        //                }
        //            }.catch(on: .main) { [weak self] error in
        //                self?.showAlert(error: error, message: "Could not sign out")
        //            }
        //        })
        //        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
        //            self?.fetchBackupsAndRenderSetupView()
        //        })
        //        present(alert, animated: true, completion: nil)
    }
}

extension SetupViewController { 

    @IBAction func loadAccountButtonPressed(_: Any) {
        //        view.endEditing(true)
        //        guard let passPhrase = passPhaseTextField.text, !passPhrase.isEmpty else {
        //            showAlert(message: "setup_enter_pass_phrase".localized)
        //            return
        //        }
        //        showSpinner()
        //
        //        switch setupAction {
        //        case .recoverKey:
        //            recoverAccountWithBackups(with: passPhrase)
        //        case .createKey:
        //            setupAccountWithGeneratedKey(with: passPhrase)
        //        }
    }

    private func recoverAccountWithBackups(with passPhrase: String) {
        let matchingBackups: [KeyDetails] = fetchedEncryptedPrvs
            .compactMap { (key) -> KeyDetails? in
                guard let prv = key.private else { return nil }
                guard let r = try? Core.decryptKey(armoredPrv: prv, passphrase: passPhrase), r.decryptedKey != nil else { return nil }
                return key
        }
        guard matchingBackups.count > 0 else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        try! storePrvs(prvs: matchingBackups, passPhrase: passPhrase, source: .generated)
        moveToMainFlow()
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
            self?.moveToMainFlow()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not finish setup, please try again")
        }
    }

    private func moveToMainFlow() {
        GlobalRouter().reset()
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


}

// MARK: - Events

extension SetupViewController {
    private func useOtherAccount() {
        userService.signOut().then(on: .main) { [weak self] _ in
            self?.router.reset()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "Could not switch accounts")
        }
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode()
            case .passPrase:
                return SetupPassPraseNode()
            case .action:
                return SetupButtonNode(SetupButtonType.loadAccount.attributedTitle) {

                }
            case .optionalAction:
                return SetupButtonNode(SetupStyle.useAnotherAccountTitle, color: .white) { [weak self] in
                    self?.useOtherAccount()
                }
            default: return ASCellNode()
            }
        }



        //        let imageHeight = tableNode.bounds.size.height * 0.2
        //
        //        return { [weak self] in
        //            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
        //            switch part {
        //            case .links:
        //                return LinkButtonNode(SignInLinks.allCases) { [weak self] action in
        //                    self?.handle(option: action)
        //                }
        //            case .logo:
        //                return SignInImageNode(UIImage(named: "full-logo"), height: imageHeight)
        //            case .description:
        //                let title = "sign_in_description"
        //                    .localized
        //                    .attributed(.medium(13), color: .textColor, alignment: .center)
        //                return SignInDescriptionNode(title)
        //            case .gmail:
        //                return SigninButtonNode(.gmail) { [weak self] in
        //                    self?.signInWithGmail()
        //                }
        //            case .outlook:
        //                return SigninButtonNode(.outlook) { [weak self] in
        //                    self?.signInWithOutlook()
        //                }
        //            }
        //        }
    }
}

final class SetupTitleNode: ASCellNode {
    private let textNode = ASTextNode()

    init(_ title: NSAttributedString = SetupStyle.title) {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        textNode.attributedText = title
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 502, left: 16, bottom: 16, right: 16),
            child: ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: textNode)
        )
    }
}



final class SetupPassPraseNode: ASCellNode {
    private let line = ASDisplayNode()
    private let textField = ASEditableTextNode()

    init(_ placeholder: NSAttributedString = SetupStyle.passPrasePlaceholder) {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        textField.attributedPlaceholderText = placeholder
        textField.delegate = self
        textField.isSecureTextEntry = true
        line.style.flexGrow = 1.0
        line.backgroundColor = .red
        line.style.preferredSize.height = 3
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 32, left: 16, bottom: 16, right: 16),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: ASStackLayoutSpec(
                    direction: .horizontal,
                    spacing: 1,
                    justifyContent: .center,
                    alignItems: .baselineFirst,
                    children: [
                        textField,
                        line
                    ])
            )
        )
    }
}

extension SetupPassPraseNode: ASEditableTextNodeDelegate {
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.rangeOfCharacter(from: .newlines) != nil else { return true }
        editableTextNode.resignFirstResponder()
        return false
    }
}


enum SetupButtonType {
    case loadAccount, createKey

    var title: String {
        switch self {
        case .loadAccount: return "setup_load".localized
        case .createKey: return "setup_create_key".localized
        }
    }

    var attributedTitle: NSAttributedString {
        title.attributed(.regular(17), color: .white, alignment: .center)
    }
}

final class SetupButtonNode: ASCellNode {
    private var onTap: (() -> Void)?
    private lazy var button = ButtonNode() { [weak self] in
        self?.onTap?()
    }

    init(_ title: NSAttributedString, color: UIColor? = nil, action: (() -> Void)?) {
        self.onTap = action
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        button.cornerRadius = 5
        button.backgroundColor = color ?? .main
        button.style.preferredSize.height = 50
        button.setAttributedTitle(title, for: .normal)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24),
            child: button
        )
    }
}

enum SetupStyle {
    static let title = "setup_title".localized.attributed(.bold(35), color: .black, alignment: .center)
    static let passPrasePlaceholder = "setup_enter".localized.attributed(.bold(16), color: .darkGray, alignment: .center)
    static let useAnotherAccountTitle = "setup_use_another".localized.attributed(.regular(15), color: .systemTeal, alignment: .center)
}


// TODO: - Refactor with this button
final class ButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

    init(_ action: (() -> Void)?) {
        self.onTap = action
        super.init()
        addTarget(self, action: #selector(handleTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
