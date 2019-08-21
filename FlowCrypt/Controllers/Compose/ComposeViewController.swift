//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import Promises
import RealmSwift

class ComposeViewController: BaseViewController {
    
    @IBOutlet var txtRecipient: UITextField!
    @IBOutlet var txtSubject: UITextField!
    @IBOutlet var txtMessage: UITextView!
    @IBOutlet weak var cnstrTextViewBottom: NSLayoutConstraint!
    @IBOutlet weak var cnstrTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var btnInfo: UIButton!
    var btnAttach: UIButton!
    var btnCompose: UIButton!
    var btnBack: UIButton!
    var lblTitle: UILabel!
    
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
        if isReply {
            self.txtSubject.text = "Re: \(self.replyToSubject ?? "(no subject)")"
            self.txtRecipient.text = replyToRecipient?.mailbox ?? ""
        }
        let _ = Imap.instance.getSmtpSess() // establish session before user taps send, so that sending msg is faster once the user does tap it
        
        self.configureNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        txtMessage.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerKeyboardNotifications()
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
    
    func dismissKeyBoard() {
        self.txtMessage.resignFirstResponder()
        if isReply {
            self.txtSubject.resignFirstResponder()
        }
        self.txtRecipient.resignFirstResponder()
    }
    
    func registerKeyboardNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func configureNavigationBar() {
        btnInfo = UIButton(type: .system)
        btnInfo.setImage(UIImage(named: "help_icn")!, for: .normal)
        btnInfo.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnInfo.frame = Constants.uiBarButtonItemFrame
        btnInfo.addTarget(self, action: #selector(btnInfoTap), for: .touchUpInside)
        
        btnAttach = UIButton(type: .system)
        btnAttach.setImage(UIImage(named: "paperclip")!, for: .normal)
        btnAttach.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnAttach.frame = Constants.uiBarButtonItemFrame
        btnAttach.addTarget(self, action: #selector(btnAttachTap), for: .touchUpInside)
        
        btnCompose = UIButton(type: .system)
        btnCompose.setImage(UIImage(named: "android-send")!, for: .normal)
        btnCompose.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnCompose.frame = Constants.uiBarButtonItemFrame
        btnCompose.addTarget(self, action: #selector(btnComposeTap), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [btnInfo, btnAttach, btnCompose])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        
        btnBack = UIButton(type: .system)
        btnBack.setImage(UIImage(named: "arrow-left-c"), for: .normal)
        btnBack.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
        btnBack.frame = Constants.uiBarButtonItemFrame
        btnBack.addTarget(self, action: #selector(btnBackTap), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnBack)
    }
    
    @objc
    private func btnBackTap() {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func btnAttachTap() {
        #warning("ToDo")
        showToast("Attachments not implemented yet", duration: 0.7)
    }
    
    @objc
    private func btnComposeTap() {
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
            self.btnBackTap()
        }, fail: Language.could_not_compose_message)
    }
    
    @objc
    private func btnInfoTap() {
        #warning("ToDo")
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
        
        guard txtMessage.isFirstResponder else { return }
        scrollView.scrollIndicatorInsets = txtMessage.contentInset
        
        guard let selectedRange = txtMessage.selectedTextRange else { return }
        let rect = txtMessage.caretRect(for: selectedRange.start)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    @objc
    private func convertStringToLowercase(textField: UITextField) {
        self.txtRecipient.text = self.txtRecipient.text?.lowercased()
    }
    
}

extension ComposeViewController: UITextViewDelegate {
    
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
}

extension ComposeViewController: UITextFieldDelegate {
    
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
    
}
