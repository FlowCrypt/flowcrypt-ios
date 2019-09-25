//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import Promises
import RealmSwift

extension ComposeViewController {
    static func instance(with input: ComposeViewController.Input) -> ComposeViewController {
        let vc = UIStoryboard.main.instantiate(ComposeViewController.self)
        vc.viewModel = input
        return vc
    }
}

final class ComposeViewController: UIViewController {

    struct Input {
        let isReply: Bool
        let replyToRecipient: MCOAddress?
        let replyToSubject: String?
        let replyToMime: Data?
    }

    private enum Constants {
        static let yourMessage = "Your message"
        static let sending = "Sending"
        static let enterRecipient = "Enter recipient"
        static let noPgp = "Recipient doesn't seem to have encryption set up"
        static let noSenderPgp = "Missing sender public key. Is FlowCrypt iOS app well set up?"
        static let composeError = "Could not compose message"
        static let replySent = "Reply successfully sent"
        static let messageSent = "Encrypted message sent"
        static let enterSubject = "Enter subject"
        static let enterMessage = "Enter secure message"
    }

    @IBOutlet weak var txtRecipient: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var txtMessage: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!

    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private let notificationCenter = NotificationCenter.default
    private let dataManager = DataManager.shared
    private let attesterApi = AttesterApi.shared
    private var viewModel = Input(isReply: false, replyToRecipient: nil, replyToSubject: nil, replyToMime: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupUI()
        registerKeyboardNotifications()

        // establish session before user taps send, so that sending msg is faster once the user does tap it
        imap.getSmtpSess()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        txtMessage.resignFirstResponder()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}

// MARK - Setup UI
extension ComposeViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "paperclip"), action: (self, #selector(handleAttachTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "android-send"), action: (self, #selector(handleSendTap)))
            ]
        )
    }

    private func setupUI() {
        [txtSubject, txtRecipient]
            .forEach { $0.setTextInset() }

        scrollView.delegate = self
        scrollView.keyboardDismissMode = .interactive

        txtRecipient.addTarget(
            self,
            action: #selector(ComposeViewController.convertStringToLowercase(textField:)),
            for: UIControl.Event.editingChanged
        )

        txtMessage.delegate = self
        txtMessage.textColor = UIColor.lightGray

        if viewModel.isReply {
            txtSubject.text = "Re: \(viewModel.replyToSubject ?? "(no subject)")"
            txtRecipient.text = viewModel.replyToRecipient?.mailbox ?? ""
        }
    }
}

// MARK - Keyboard
extension ComposeViewController {
    private func registerKeyboardNotifications() {
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { assertionFailure("Check user info"); return }


        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }

        guard txtMessage.isFirstResponder else { return }
        scrollView.scrollIndicatorInsets = txtMessage.contentInset

        guard let selectedRange = txtMessage.selectedTextRange else { return }
        let rect = txtMessage.caretRect(for: selectedRange.start)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

// MARK - Handle actions
extension ComposeViewController {
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }

    @objc private func handleAttachTap() {
        #warning("ToDo")
        showToast("Attachments not implemented yet")
    }

    @objc private func handleSendTap() {
        sendMsgTapHandler()
    }

    private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func convertStringToLowercase(textField: UITextField) {
        txtRecipient.text = txtRecipient.text?.lowercased()
    }
}

extension ComposeViewController {

    private func sendMsgTapHandler() {
        dismissKeyboard()

        guard isInputValid(),
            let email = txtRecipient.text,
            let text = txtMessage.text
        else { return }

        showSpinner(Constants.sending)

        Promise<Void> { [weak self] in
            guard let self = self else { return }
            let lookupRes = try await(self.attesterApi.lookupEmail(email: email))
            guard let recipientPubkey = lookupRes.armored else { return self.showAlert(message: Constants.noPgp) }
            let realm = try Realm() // TODO: Anton - Refactor to use db service
            guard let myPubkey = realm.objects(KeyInfo.self).map( { $0.public }).first else { return self.showAlert(message: Constants.noSenderPgp) }
            let encrypted = self.encryptMsg(pubkeys: [myPubkey, recipientPubkey], message: text, email: email)
            try await(self.imap.sendMail(mime: encrypted.mimeEncoded))
        }.then(on: .main) { [weak self] in
            self?.hideSpinner()
            self?.showToast(self?.viewModel.isReply ?? false ? Constants.replySent : Constants.messageSent)
            self?.navigationController?.popViewController(animated: true)
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: Constants.composeError)
        }
    }

    private func encryptMsg(pubkeys: [String], message: String, email: String) -> CoreRes.ComposeEmail {
        let subject = viewModel.isReply
            ? "Re: \(viewModel.replyToSubject ?? "(no subject)")"
            : txtSubject.text ?? "(no subject)"
        let replyToMimeMsg = viewModel.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }
        let msg = SendableMsg(
            text: message,
            to: [email],
            cc: [],
            bcc: [],
            from: dataManager.currentUser()?.email ?? "",
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: []
        )
        return try! Core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: pubkeys)
    }

    private func isInputValid() -> Bool {
        guard txtRecipient.text?.hasContent ?? false else {
            showAlert(message: Constants.enterRecipient)
            return false
        }
        guard viewModel.isReply || txtSubject.text?.hasContent ?? false else {
            showAlert(message: Constants.enterSubject)
            return false
        }
        guard txtMessage.text?.hasContent ?? false else {
            showAlert(message: Constants.enterMessage)
            return false
        }
        return true
    }

}

// MARK - UITextViewDelegate, UITextFieldDelegate
extension ComposeViewController: UITextViewDelegate, UITextFieldDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == Constants.yourMessage || textView.text == Language.message_placeholder {
            txtMessage.textColor = .black
            txtMessage.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" || textView.text == "\n" {
            txtMessage.textColor = UIColor.lightGray
            txtMessage.text = Constants.yourMessage
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.txtRecipient {
            txtSubject.becomeFirstResponder()
        }
        if !viewModel.isReply && textField == self.txtSubject {
            txtMessage.becomeFirstResponder()
            return false
        }
        return true
    }
}
