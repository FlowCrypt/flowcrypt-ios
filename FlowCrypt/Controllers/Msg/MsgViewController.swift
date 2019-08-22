//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

protocol MsgViewControllerDelegate {
    func movedOrUpdated(objMessage: MCOIMAPMessage)
}

class MsgViewController: BaseViewController {
    
    @IBOutlet var lblSender: UILabel!
    @IBOutlet var lblSubject: UILabel!
    @IBOutlet var lblTIme: UILabel!
    @IBOutlet var lblBody: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContent: UIView!

    // TODO: Refactor due to https://github.com/FlowCrypt/flowcrypt-ios/issues/38
    var btnInfo: UIButton!
    var btnArchive: UIButton!
    var btnTrash: UIButton!
    var btnMail: UIButton!
    var btnBack: UIButton!
    
    var objMessage = MCOIMAPMessage()
    var bodyMessage: Data?
    var path = ""

    // TODO: - Should be weak to avoid memory leaks(investigate)
    var delegate: MsgViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblSender.text = objMessage.header.sender.mailbox ?? "(unknown sender)"
        self.lblSubject.text = objMessage.header.subject ?? "(no subject)"
        self.lblBody.numberOfLines = 0
        self.lblTIme.text = Constants.convertDate(date: objMessage.header.date)
        self.showSpinner(Language.loading, isUserInteractionEnabled: true)
        self.async({ () -> CoreRes.ParseDecryptMsg in
            let mime = try await(Imap.instance.fetchMsg(message: self.objMessage, folder: self.path))
            self.bodyMessage = mime
            self.hideSpinner()
            let realm = try Realm()
            let keys = PrvKeyInfo.from(realm: realm.objects(KeyInfo.self))
            let decrypted = try Core.parseDecryptMsg(encrypted: mime, keys: keys, msgPwd: nil, isEmail: true)
            return decrypted
        }, then: { decrypted in
            let decryptErrBlock = decrypted.blocks.first(where: { $0.decryptErr != nil })
            if decryptErrBlock == nil {
                self.renderMsgBody(decrypted.text, color: decrypted.replyType == CoreRes.ReplyType.encrypted ? Constants.green : UIColor.black)
            } else if let e = decryptErrBlock?.decryptErr?.error {
                self.renderMsgBody(
                    "Dould not decrypt message:\n\(e.type)\n\n\(e.message)\n\n\(decryptErrBlock!.content)",
                    color: .red
                )
            }
            self.markAsReadIfNotAlreadyMarked()
        }, fail: Language.could_not_open_message)
        self.configureNavigationBar()
    }

    // TODO: Refactor due to https://github.com/FlowCrypt/flowcrypt-ios/issues/38
    private func configureNavigationBar() {
        btnInfo = UIButton(type: .system)
        btnInfo.setImage(UIImage(named: "help_icn")!, for: .normal)
        btnInfo.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnInfo.frame = Constants.uiBarButtonItemFrame
        btnInfo.addTarget(self, action: #selector(btnInfoTap), for: .touchUpInside)
        
        btnArchive = UIButton(type: .system)
        btnArchive.setImage(UIImage(named: "archive")!, for: .normal)
        btnArchive.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnArchive.frame = Constants.uiBarButtonItemFrame
        btnArchive.addTarget(self, action: #selector(btnArchiveTap), for: .touchUpInside)

        btnTrash = UIButton(type: .system)
        btnTrash.setImage(UIImage(named: "trash")!, for: .normal)
        btnTrash.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnTrash.frame = Constants.uiBarButtonItemFrame
        btnTrash.addTarget(self, action: #selector(btnTrashTap), for: .touchUpInside)
        
        btnMail = UIButton(type: .system)
        btnMail.setImage(UIImage(named: "mail")!, for: .normal)
        btnMail.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnMail.frame = Constants.uiBarButtonItemFrame
        btnMail.addTarget(self, action: #selector(btnMailTap), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [btnInfo, btnArchive, btnTrash, btnMail])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15
        
        if self.path == "[Gmail]/Trash" {
            btnTrash.isHidden = true
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        
        btnBack = UIButton(type: .system)
        btnBack.setImage(UIImage(named: "arrow-left-c"), for: .normal)
        btnBack.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
        btnBack.frame = Constants.uiBarButtonItemFrame
        btnBack.addTarget(self, action: #selector(btnBackTap), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnBack)
    }
    
    func renderMsgBody(_ text: String, color: UIColor = UIColor.black) {
        self.lblBody.text = text
        self.lblBody.textColor = color
        self.lblBody.sizeToFit()
        self.scrollView.contentSize = self.scrollViewContent.frame.size;
    }
    
    func markAsReadIfNotAlreadyMarked() {
        if !objMessage.flags.isSuperset(of: MCOMessageFlag.seen) {
            self.objMessage.flags.formUnion(MCOMessageFlag.seen)
            let _ = Imap.instance.markAsRead(message: self.objMessage, folder: self.path) // async, do not await
            guard let delegate = self.delegate else { return }
            delegate.movedOrUpdated(objMessage: self.objMessage)            
        }
    }
    
    @objc
    private func btnInfoTap() {
        #warning("ToDo")
        showToast("Info not implemented yet")
    }
    
    @objc
    private func btnMailTap() {
        #warning("ToDo")
        showToast("Not implemented yet")
    }
    
    @objc
    private func btnTrashTap() {
        self.async({
            let _ = try await(Imap.instance.moveMsg(msg: self.objMessage, folder: self.path, destFolder: "[Gmail]/Trash"))
        }, then: {
            self.onMsgUpdateSuccess(toast: Language.moved_to_trash)
        })
    }
    
    @objc
    private func btnArchiveTap() {
        self.objMessage.flags = MCOMessageFlag.deleted
        self.async({
            let _ = try await(Imap.instance.pushUpdatedMsgFlags(msg: self.objMessage, folder: self.path))
        }, then: {
            self.onMsgUpdateSuccess(toast: Language.email_archived)
        })
    }
    
    func onMsgUpdateSuccess(toast: String) {
        self.hideSpinner()
        if let d = self.delegate {
            d.movedOrUpdated(objMessage: self.objMessage)
        }
        self.showToast(toast)
        self.btnBackTap()
    }
    
    @objc
    private func btnBackTap() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnReplyTap(sender: UIButton) {
        let replyVc = self.instantiate(viewController: ComposeViewController.self)
        replyVc.isReply = true
        replyVc.replyToSubject = self.objMessage.header.subject
        replyVc.replyToRecipient = self.objMessage.header.from
        replyVc.replyToMime = self.bodyMessage
        
        self.navigationController?.pushViewController(replyVc, animated: true)
    }
    
}
