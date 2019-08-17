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
    @IBOutlet weak var cnstrTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var isReply = false;
    var replyToRecipient: MCOAddress?
    var replyToSubject: String?
    var replyToMime: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setPadding(textField: txtRecipient)
        self.setPadding(textField: txtSubject)
        self.txtMessage.delegate = self
        scrollView.delegate = self
        scrollView.keyboardDismissMode = .interactive
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
    
    func registerKeyboardNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc
    private func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = txtMessage.contentInset
        
        guard let selectedRange = txtMessage.selectedTextRange else { return }
        let rect = txtMessage.caretRect(for: selectedRange.start)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        txtMessage.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
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
