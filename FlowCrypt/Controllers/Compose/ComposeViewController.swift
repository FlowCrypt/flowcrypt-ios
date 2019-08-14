//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import Promises
import RealmSwift

class ComposeViewController: BaseViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet var txtRecipient: UITextField!
    @IBOutlet var txtSubject: UITextField!
    @IBOutlet var txtMessage: UITextView!
    @IBOutlet var btnCompose: UIBarButtonItem!
    @IBOutlet var btnAttach: UIBarButtonItem!
    @IBOutlet var btnInfo: UIBarButtonItem!
    @IBOutlet weak var cnstrTextViewBottom: NSLayoutConstraint!
    
    var isReply = false;
    var replyToRecipient: MCOAddress?
    var replyToSubject: String?
    var replyToMime: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setPadding(textField: txtRecipient)
        self.setPadding(textField: txtSubject)
        self.txtMessage.delegate = self
        self.txtMessage.keyboardDismissMode = .onDrag
        self.txtRecipient.addTarget(self, action: #selector(ComposeViewController.convertStringToLowercase(textField:)), for: UIControl.Event.editingChanged)
        self.txtMessage.textColor = UIColor.lightGray
        btnCompose.imageInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        btnAttach.imageInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: -15)
        btnInfo.imageInsets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: -15)
        if isReply {
            self.txtSubject.text = "Re: \(self.replyToSubject ?? "(no subject)")"
            self.txtRecipient.text = replyToRecipient?.mailbox ?? ""
        }
        let _ = Imap.instance.getSmtpSess() // establish session before user taps send, so that sending msg is faster once the user does tap it
    }

    func isInputValid() -> Bool {
        guard self.txtRecipient.text!.hasContent else {
            self.showErrAlert(Language.enter_recipient)
            return false
        }
        guard isReply || self.txtSubject.text!.hasContent else {
            self.showErrAlert(Language.enter_subject)
            return false
        }
        guard self.txtMessage.text.hasContent else {
            self.showErrAlert(Language.enter_message)
            return false
        }
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerKeyboardNotifications()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.txtRecipient {
            self.txtSubject.becomeFirstResponder()
        }
        if !isReply && textField == self.txtSubject {
            self.txtMessage.becomeFirstResponder()
            return false
        }
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == Language.your_message || textView.text == Language.message_placeholder {
            self.txtMessage.textColor = .black
            self.txtMessage.text = ""
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" || textView.text == "\n" {
            self.txtMessage.textColor = UIColor.lightGray
            self.txtMessage.text = Language.your_message
        }
    }

    func textViewDidChange(_ textView: UITextView) {
//        var line: CGRect? = nil
//        if let start = textView.selectedTextRange?.start {
//            line = textView.caretRect(for: start)
//        }
//        let overflow = (line?.origin.y ?? 0.0) + (line?.size.height ?? 0.0) - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top)
//        if overflow > 0 {
//            // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
//            // Scroll caret to visible area
//            var offset = textView.contentOffset
//            offset.y += overflow + 7 // leave 7 pixels margin
//            // Cannot animate with setContentOffset:animated: or caret will not appear
//            UIView.animate(withDuration: 0.2, animations: {
//                textView.contentOffset = offset
//            })
//        }
    }

    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        txtMessage.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
//        updateKeyboard(notification: notification)


        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

        let keyboardHeight = keyboardSize?.height

        if #available(iOS 11.0, *){

            self.cnstrTextViewBottom.constant = keyboardHeight! - view.safeAreaInsets.bottom
        }
        else {
            self.cnstrTextViewBottom.constant = view.safeAreaInsets.bottom
        }

        UIView.animate(withDuration: 0.5){

            self.view.layoutIfNeeded()

        }
    }

    var oldFrame: CGRect!
    func updateKeyboard(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.oldFrame = self.view.frame
                self.view.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height - keyboardSize.height - view.safeAreaInsets.bottom)
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.view.frame = self.oldFrame
//        })

        self.cnstrTextViewBottom.constant =  0
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func convertStringToLowercase(textField: UITextField) {
        self.txtRecipient.text = self.txtRecipient.text?.lowercased()
    }

    func dismissKeyBoard() {
        self.txtMessage.resignFirstResponder()
        if isReply {
            self.txtSubject.resignFirstResponder()
        }
        self.txtRecipient.resignFirstResponder()
    }

    @IBAction func btnBackTap(sender: AnyObject) {
        let _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func btnComposeTap(sender: AnyObject) {
        self.dismissKeyBoard()
        guard self.isInputValid() else { return }
        self.showSpinner(Language.sending)
        let email = self.txtRecipient.text!
        let text = self.txtMessage.text!
        let subject = isReply ? "Re: \(replyToSubject ?? "(no subject)")" : self.txtSubject.text ?? "(no subject)"
        let from = GoogleApi.instance.getEmail()
        let replyToMimeMsg = replyToMime != nil ? String(data: replyToMime!, encoding: .utf8) : nil
        let realm = try! Realm()
        var pubKeys = Array(realm.objects(KeyInfo.self).map { $0.public })
        self.async({
            let recipientPub = try await(AttesterApi.lookupEmail(email: email))
            guard recipientPub.armored != nil else { return self.showErrAlert(Language.no_pgp) }
            pubKeys.append(recipientPub.armored!)
            let msg = SendableMsg(text: text, to: [email], cc: [], bcc: [], from: from, subject: subject, replyToMimeMsg: replyToMimeMsg)
            let composeRes = try Core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: pubKeys);
            let _ = try await(Imap.instance.sendMail(mime: composeRes.mimeEncoded))
        }, then: {
            self.hideSpinner()
            self.showToast(self.isReply ? Language.encrypted_reply_sent : Language.encrypted_message_sent)
            self.btnBackTap(sender: UIBarButtonItem())
        }, fail: Language.could_not_compose_message)
    }

}
